require 'rails_helper'

describe 'ModelEvents::EmployerInitialEligibilityDenialNotice', dbclean: :after_each  do
  let(:model_event)  { "ineligible_initial_application_submitted" }
  let(:notice_event) { "employer_initial_eligibility_denial_notice" }
  let(:employer_profile){ create :employer_profile}
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let(:person){ create :person}
  let(:benefit_group) { FactoryGirl.build(:benefit_group) }
  let!(:model_instance) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'draft', :fte_count => 55) }
  
  before :each do
    allow(employer_profile).to receive(:is_primary_office_local?).and_return(false)
  end

  describe "ModelEvent" do
    context "when initial employer denial notice" do
      let(:prior_month_open_enrollment_start)  { TimeKeeper.date_of_record.beginning_of_month + Settings.aca.shop_market.open_enrollment.monthly_end_on - Settings.aca.shop_market.open_enrollment.minimum_length.days - 1.day}
      let(:valid_effective_date)   { (prior_month_open_enrollment_start - Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months).beginning_of_month }
      before do
        model_instance.effective_date = valid_effective_date
        model_instance.end_on = valid_effective_date + Settings.aca.shop_market.benefit_period.length_minimum.year.years - 1.day
        model_instance.benefit_groups = [benefit_group]
      end
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:plan_year_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :ineligible_initial_application_submitted, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.publish!
      end
    end
  end

  describe "NoticeTrigger" do
    context "when initial employer denial" do
      subject { Observers::NoticeObserver.new }
      let(:model_event) { ModelEvents::ModelEvent.new(:ineligible_initial_application_submitted, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.employer_initial_eligibility_denial_notice"
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        subject.plan_year_update(model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      ["employer_profile.notice_date", 
        "employer_profile.employer_name",
        "employer_profile.plan_year.warnings",
        "employer_profile.broker.primary_fullname", 
        "employer_profile.broker.organization", 
        "employer_profile.broker.phone", 
        "employer_profile.broker.email", 
        "employer_profile.plan_year.enrollment_errors", 
        "employer_profile.broker_present?"
      ]
    }

    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }

    let(:payload)   { {
      "event_object_kind" => "PlanYear",
      "event_object_id" => model_instance.id
    } }

    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(employer_profile)
      allow(subject).to receive(:payload).and_return(payload)
    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    it "should return employer name" do
      expect(merge_model.employer_name).to eq employer_profile.legal_name
    end

    it "should return false when there is no broker linked to employer" do
      expect(merge_model.broker_present?).to be_falsey
    end
  end
end
