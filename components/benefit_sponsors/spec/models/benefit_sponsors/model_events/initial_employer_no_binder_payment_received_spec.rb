require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe 'BenefitSponsors::ModelEvents::InitialEmployerNoBinderPaymentReceived', :dbclean => :after_each do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:model_event) { "initial_employer_no_binder_payment_received" }
  let(:notice_event1) { "initial_employer_no_binder_payment_received" }
  let(:notice_event2) { "notice_to_ee_that_er_plan_year_will_not_be_written" }

  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:current_effective_date) { start_on }
  let(:aasm_state) { :enrollment_ineligible }
  let(:benefit_sponsorship_state) { :initial_enrollment_ineligible }
  let(:employer_profile) { abc_profile }
  let(:benefit_application) { initial_application }

  let!(:date_mock_object) { BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new.calculate_open_enrollment_date(TimeKeeper.date_of_record.next_month.beginning_of_month)[:binder_payment_due_date].next_day }
  let!(:person) { FactoryBot.create(:person, :with_family) }
  let!(:census_employee)  { FactoryBot.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: employer_profile ) }
  let!(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: employer_profile, census_employee_id: census_employee.id)}

  before do
    census_employee.update_attributes(employee_role_id: employee_role.id)
  end

  describe "ModelEvent" do
    it "should trigger model event" do
      benefit_application.class.observer_peers.keys.select { |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
        expect(observer).to receive(:process_application_events) do |_instance, model_event|
          expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
          expect(model_event).to have_attributes(:event_key => :initial_employer_no_binder_payment_received, :klass_instance => benefit_application, :options => {})
        end

        expect(observer).to receive(:process_application_events) do |_instance, model_event|
          expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
        end
      end
      BenefitSponsors::BenefitApplications::BenefitApplication.date_change_event(date_mock_object)
    end
  end

  describe "NoticeTrigger" do
    context "whne binder payment is missed" do
      subject { BenefitSponsors::Observers::NoticeObserver.new  }
      let(:model_event) { BenefitSponsors::ModelEvents::ModelEvent.new(:initial_employer_no_binder_payment_received, BenefitSponsors::BenefitApplications::BenefitApplication, {}) }

      it "should trigger notice event for initial employer and employees" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.initial_employer_no_binder_payment_received"
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
          expect(payload[:event_object_id]).to eq benefit_application.id.to_s
        end

        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.notice_to_ee_that_er_plan_year_will_not_be_written"
          expect(payload[:employee_role_id]).to eq census_employee.employee_role.id.to_s
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
          expect(payload[:event_object_id]).to eq benefit_application.id.to_s
        end
        subject.process_application_events(benefit_application, model_event)
      end
    end
  end

  describe "NoticeBuilder employee" do

    let(:data_elements) {
      [
          "employee_profile.notice_date",
          "employee_profile.employer_name",
          "employee_profile.benefit_application.current_py_start_date",
          "employee_profile.broker.primary_fullname",
          "employee_profile.broker.organization",
          "employee_profile.broker.phone",
          "employee_profile.broker.email",
          "employee_profile.broker_present?"
      ]
    }
    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "BenefitSponsors::BenefitApplications::BenefitApplication",
        "event_object_id" => benefit_application.id
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(employee_role)
      allow(subject).to receive(:payload).and_return(payload)
      BenefitSponsors::BenefitApplications::BenefitApplication.date_change_event(date_mock_object)
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

    it "should return plan year start date" do
      expect(merge_model.benefit_application.current_py_start_date).to eq benefit_application.start_on.strftime('%m/%d/%Y')
    end

    it "should return broker" do
      expect(merge_model.broker_present?).to be_falsey
    end
  end

   describe "NoticeBuilder employer" do

    let(:data_elements) {
      [
          "employer_profile.notice_date",
          "employer_profile.employer_name",
          "employer_profile.benefit_application.current_py_start_date",
          "employer_profile.benefit_application.binder_payment_due_date",
          "employer_profile.benefit_application.next_available_start_date",
          "employer_profile.benefit_application.next_application_deadline",
          "employer_profile.broker.primary_fullname",
          "employer_profile.broker.organization",
          "employer_profile.broker.phone",
          "employer_profile.broker.email",
          "employer_profile.broker_present?"
      ]
    }
    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "BenefitSponsors::BenefitApplications::BenefitApplication",
        "event_object_id" => benefit_application.id
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }
    let(:next_available_start_date) {BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new.calculate_start_on_dates.first.to_date}

    before do
      allow(subject).to receive(:resource).and_return(employer_profile)
      allow(subject).to receive(:payload).and_return(payload)
      BenefitSponsors::BenefitApplications::BenefitApplication.date_change_event(date_mock_object)
    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    it "should return next available start date" do
      expect(merge_model.benefit_application.next_available_start_date).to eq next_available_start_date.to_s
    end

    it "should return next application deadline" do
      expect(merge_model.benefit_application.next_application_deadline).to eq Date.new(next_available_start_date.year, next_available_start_date.prev_month.month, Settings.aca.shop_market.initial_application.advertised_deadline_of_month).to_s
    end

    it "should return employer name" do
      expect(merge_model.employer_name).to eq employer_profile.legal_name
    end

    it "should return plan year start date" do
      expect(merge_model.benefit_application.current_py_start_date).to eq benefit_application.start_on.strftime('%m/%d/%Y')
    end

    it "should return binder payment due date" do
      expect(merge_model.benefit_application.binder_payment_due_date).to eq date_mock_object.prev_day.strftime('%m/%d/%Y')
    end

    it "should return broker" do
      expect(merge_model.broker_present?).to be_falsey
    end
  end
end

