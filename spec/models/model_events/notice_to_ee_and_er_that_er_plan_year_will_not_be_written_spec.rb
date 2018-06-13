require 'rails_helper'

describe 'ModelEvents::InitialEmployerNoBinderPaymentReceived', :dbclean => :after_each do

  let(:model_event) { "initial_employer_no_binder_payment_received" }
  let(:notice_event1) { "initial_employer_no_binder_payment_received" }
  let(:notice_event2) { "notice_to_ee_that_er_plan_year_will_not_be_written" }
  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:employer_profile){ FactoryGirl.create(:employer_profile)}
  let!(:model_instance) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'enrolled' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: model_instance, title: "Benefits #{model_instance.start_on.year}") }
  let!(:date_mock_object) { model_instance.class.calculate_open_enrollment_date(start_on)[:binder_payment_due_date].next_day }
  let!(:person) { FactoryGirl.create(:person, :with_family) }
  let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let!(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer_profile, person: person) }

  before do
    census_employee.update_attributes(employee_role_id: employee_role.id)
  end

  describe "ModelEvent" do
    context "when initial employer missed binder payment deadline" do
      it "should trigger model event" do
        expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(recipient: employer_profile, event_object: model_instance, notice_event: notice_event1).and_return(true)
        expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(recipient: employee_role, event_object: model_instance, notice_event: notice_event2).and_return(true)
        PlanYear.date_change_event(date_mock_object)
      end
    end
  end

  describe "NoticeTrigger" do
    context "whne binder payment is missed" do
      subject { Observers::NoticeObserver.new }

      let(:model_event) { ModelEvents::ModelEvent.new(:initial_employer_no_binder_payment_received, PlanYear, {}) }

      it "should trigger notice event for initial employer and employees" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.initial_employer_no_binder_payment_received"
          expect(payload[:employer_id]).to eq employer_profile.send(:hbx_id).to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.notice_to_ee_that_er_plan_year_will_not_be_written"
          expect(payload[:employee_role_id]).to eq census_employee.employee_role.id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        subject.plan_year_date_change(model_event)
      end
    end
  end

  describe "NoticeBuilder employee" do

    let(:data_elements) {
      [
          "employee_profile.notice_date",
          "employee_profile.employer_name",
          "employee_profile.plan_year.current_py_start_date",
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
        "event_object_kind" => "PlanYear",
        "event_object_id" => model_instance.id
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(employee_role)
      allow(subject).to receive(:payload).and_return(payload)
      PlanYear.date_change_event(date_mock_object)
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
      expect(merge_model.plan_year.current_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
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
          "employer_profile.plan_year.current_py_start_date",
          "employer_profile.plan_year.binder_payment_due_date",
          "employer_profile.plan_year.monthly_employer_contribution_amount",
          "employer_profile.plan_year.next_available_start_date",
          "employer_profile.plan_year.next_application_deadline",
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
        "event_object_kind" => "PlanYear",
        "event_object_id" => model_instance.id
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }
    let(:next_available_start_date) {PlanYear.calculate_start_on_options.first.last.to_date}

    before do
      allow(subject).to receive(:resource).and_return(employer_profile)
      allow(subject).to receive(:payload).and_return(payload)
      PlanYear.date_change_event(date_mock_object)
    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    it "should return next available start date" do
      expect(merge_model.plan_year.next_available_start_date).to eq next_available_start_date.to_s
    end

    it "should return next application deadline" do
      expect(merge_model.plan_year.next_application_deadline).to eq Date.new(next_available_start_date.year, next_available_start_date.prev_month.month, Settings.aca.shop_market.initial_application.advertised_deadline_of_month).to_s
    end

    it "should return employer name" do
      expect(merge_model.employer_name).to eq employer_profile.legal_name
    end

    it "should return monthly employer contribution" do
      expect(merge_model.plan_year.monthly_employer_contribution_amount).to eq ActiveSupport::NumberHelper.number_to_currency(active_benefit_group.monthly_employer_contribution_amount)
    end

    it "should return plan year start date" do
      expect(merge_model.plan_year.current_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
    end

    it "should return binder payment due date" do
      expect(merge_model.plan_year.binder_payment_due_date).to eq date_mock_object.prev_day.strftime('%m/%d/%Y')
    end

    it "should return broker" do
      expect(merge_model.broker_present?).to be_falsey
    end
  end
end

