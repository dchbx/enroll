require 'rails_helper'
 
RSpec.describe 'BenefitSponsors::ModelEvents::InitialEmployerOpenEnrollmentCompleted', dbclean: :after_each do

  let(:model_event) { "employer_open_enrollment_completed" }
  let(:notice_event) { "initial_employer_open_enrollment_completed" }
  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month}
  let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:employer_profile)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
  let!(:model_instance) { FactoryBot.create(:benefit_sponsors_benefit_application,
    :with_benefit_package,
    :benefit_sponsorship => benefit_sponsorship,
    :aasm_state => 'enrollment_open',
    :effective_period =>  start_on..(start_on + 1.year) - 1.day
  )}

  let(:enrollment_policy) {instance_double("BenefitMarkets::BusinessRulesEngine::BusinessPolicy", success_results: "Success") }
  let!(:date_mock_object) { double("Date", day: (model_instance.open_enrollment_period.max + 1.days).day)}

  before do
    allow(model_instance).to receive(:is_renewing?).and_return(false)
  end

  describe "ModelEvent" do
    it "should trigger model event" do
      model_instance.class.observer_peers.keys.select { |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
        expect(observer).to receive(:process_application_events) do |_model_instance, model_event|
          expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
          expect(model_event).to have_attributes(:event_key => :employer_open_enrollment_completed, :klass_instance => model_instance, :options => {})
        end
      end
      allow_any_instance_of(BenefitMarkets::BusinessRulesEngine::BusinessPolicy).to receive(:is_satisfied?).with(model_instance).and_return true
      model_instance.end_open_enrollment!
    end
  end

  describe "NoticeTrigger" do
    context "open enrollment end" do
      subject { BenefitSponsors::Observers::NoticeObserver.new }
      let(:model_event) { BenefitSponsors::ModelEvents::ModelEvent.new(:employer_open_enrollment_completed, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.initial_employer_open_enrollment_completed"
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        allow_any_instance_of(BenefitMarkets::BusinessRulesEngine::BusinessPolicy).to receive(:is_satisfied?).with(model_instance).and_return true
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
        "employer_profile.benefit_application.initial_py_publish_due_date", 
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
      end

      it "should retrun merge mdoel" do
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

      it "should return publish due date" do
        expect(merge_model.benefit_application.initial_py_publish_due_date).to eq Date.new(model_instance.start_on.prev_month.year, model_instance.start_on.prev_month.month, Settings.aca.shop_market.initial_application.publish_due_day_of_month).strftime('%m/%d/%Y')
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end
end
