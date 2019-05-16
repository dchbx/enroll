require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::InitialEmployerFirstRemainderToPublishPlanYear', dbclean: :around_each do

  let(:model_event) { "initial_employer_first_reminder_to_publish_plan_year" }
  let(:notice_event) { "initial_employer_first_reminder_to_publish_plan_year" }
  let(:start_on) { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
  let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:employer_profile)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
  let!(:model_instance) { FactoryBot.create(:benefit_sponsors_benefit_application,
    :with_benefit_package,
    :benefit_sponsorship => benefit_sponsorship,
    :aasm_state => 'draft',
    :effective_period =>  start_on..(start_on + 1.year) - 1.day
  )}
  let!(:date_mock_object) { double("Date", day: Settings.aca.shop_market.initial_application.advertised_deadline_of_month - 2 )}


  describe "ModelEvent" do
    it "should trigger model event" do
      model_instance.class.observer_peers.keys.select{ |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
        expect(observer).to receive(:process_application_events) do |_instance, model_event|
          expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
          expect(model_event).to have_attributes(:event_key => :initial_employer_first_reminder_to_publish_plan_year, :klass_instance => model_instance, :options => {})
        end

        expect(observer).to receive(:process_application_events) do |_instance, model_event|
          expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
        end
      end
      BenefitSponsors::BenefitApplications::BenefitApplication.date_change_event(date_mock_object)
    end
  end

  describe "NoticeTrigger" do
    context "2 days prior to soft dead line" do
      subject { BenefitSponsors::Observers::NoticeObserver.new }
      let(:model_event) { BenefitSponsors::ModelEvents::ModelEvent.new(:initial_employer_first_reminder_to_publish_plan_year, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.initial_employer_first_reminder_to_publish_plan_year"
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.process_application_events(model_instance, model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employer_profile.notice_date",
        "employer_profile.employer_name",
        "employer_profile.benefit_application.current_py_start_date",
        "employer_profile.benefit_application.initial_py_publish_advertise_deadline",
        "employer_profile.broker.primary_fullname",
        "employer_profile.broker.organization",
        "employer_profile.broker.phone",
        "employer_profile.broker.email",
        "employer_profile.broker_present?"
      ]
    }
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }

    let(:payload)   { {
        "event_object_kind" => "BenefitSponsors::BenefitApplications::BenefitApplication",
        "event_object_id" => model_instance.id
    } }

    context "when notice event received" do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employer_profile)
        allow(subject).to receive(:payload).and_return(payload)
        BenefitSponsors::BenefitApplications::BenefitApplication.date_change_event(date_mock_object)
      end

      it "should retrun merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq employer_profile.legal_name
      end

      it "should return plan year start date" do
        expect(merge_model.benefit_application.current_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
      end

      it "should return advertised deadline of month" do
        expect(merge_model.benefit_application.initial_py_publish_advertise_deadline).to eq Date.new(model_instance.start_on.prev_month.year, model_instance.start_on.prev_month.month, Settings.aca.shop_market.initial_application.advertised_deadline_of_month).strftime('%m/%d/%Y')
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end
end
