require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe 'BenefitSponsors::ModelEvents::RenewalEmployerReminderToPublishPlanYearNotification', dbclean: :around_each do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application"
  include_context "setup employees with benefits"

  let(:model_event) { "renewal_employer_third_reminder_to_publish_plan_year" }
  let(:renewal_effective_date)  { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:current_effective_date)  { renewal_effective_date.prev_year }
  let(:employer_profile) { abc_profile }
  let(:model_instance) { renewal_application }

  let!(:date_mock_object) { double("Date", day: Settings.aca.shop_market.renewal_application.publish_due_day_of_month - 2 )}

  before do
    model_instance.update_attributes(:effective_period =>  renewal_effective_date..(renewal_effective_date + 1.year) - 1.day)
  end

  describe "ModelEvent" do
    it "should trigger model event" do
      model_instance.class.observer_peers.keys.select{ |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
        expect(observer).to receive(:process_application_events) do |_instance, model_event|
          expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
          expect(model_event).to have_attributes(:event_key => :renewal_employer_third_reminder_to_publish_plan_year, :klass_instance => model_instance, :options => {})
        end
        expect(observer).to receive(:process_application_events) do |_instance, model_event|
          expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
        end
      end
      BenefitSponsors::BenefitApplications::BenefitApplication.date_change_event(date_mock_object)
    end
  end

  describe "NoticeTrigger" do
    context "2 days prior to publish dead line" do
      subject { BenefitSponsors::Observers::NoticeObserver.new  }
      let(:model_event) { BenefitSponsors::ModelEvents::ModelEvent.new(:renewal_employer_third_reminder_to_publish_plan_year, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.renewal_employer_third_reminder_to_publish_plan_year"
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
          "employer_profile.benefit_application.renewal_py_start_date",
          "employer_profile.benefit_application.renewal_py_submit_due_date",
          "employer_profile.benefit_application.renewal_py_oe_end_date",
          "employer_profile.benefit_application.current_py_start_on.year",
          "employer_profile.benefit_application.renewal_py_start_on.year",
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
        expect(merge_model.benefit_application.renewal_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
      end

      it "should return publish deadline of month" do
        expect(merge_model.benefit_application.renewal_py_submit_due_date).to eq Date.new(model_instance.start_on.prev_month.year, model_instance.start_on.prev_month.month, Settings.aca.shop_market.renewal_application.publish_due_day_of_month).strftime('%m/%d/%Y')
      end

      it "should return renewal plan year open enrollment end date" do
        expect(merge_model.benefit_application.renewal_py_oe_end_date).to eq model_instance.open_enrollment_end_on.strftime('%m/%d/%Y')
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end
end
