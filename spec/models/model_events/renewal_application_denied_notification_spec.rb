require 'rails_helper'

describe 'ModelEvents::RenewalApplicationDeniedNotification' do

  let(:model_event)  { "renewal_application_denied" }

  let(:start_on) { (TimeKeeper.date_of_record + 1.months).beginning_of_month }

  let!(:employer) {
    FactoryGirl.create(:employer_with_renewing_planyear, start_on: start_on, renewal_plan_year_state: 'renewing_enrolling', aasm_state: :registered)
  }

  let(:model_instance) { employer.renewing_plan_year }
  let(:current_py) { employer.active_plan_year }

  let!(:renewing_employees) {
    employees = FactoryGirl.create_list(:census_employee_with_active_and_renewal_assignment, 5, hired_on: (TimeKeeper.date_of_record - 2.years), employer_profile: employer,
      benefit_group: employer.active_plan_year.benefit_groups.first,
      renewal_benefit_group: model_instance.benefit_groups.first,
      created_at: TimeKeeper.date_of_record.prev_year)

    employees.each do |ce|
      person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
      employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer)
      ce.update_attributes({employee_role: employee_role})
    end
  }

  let!(:employer_staff_role) {FactoryGirl.create(:employer_staff_role, aasm_state:'is_active', employer_profile_id: employer.id)}
  let(:person) { FactoryGirl.create(:person,employer_staff_roles:[employer_staff_role])}

  describe "ModelEvent" do

    before :each do
      allow(employer).to receive(:is_primary_office_local?).and_return(false)
    end

    context "when In eligible renewal application created" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:plan_year_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :renewal_application_denied, :klass_instance => model_instance, :options => {})
          end
        end

        current_date = TimeKeeper.date_of_record
        TimeKeeper.set_date_of_record_unprotected!(employer.renewing_plan_year.open_enrollment_end_on.next_day)
        model_instance.advance_date!
        TimeKeeper.set_date_of_record_unprotected!(current_date)
      end
    end
  end

  describe "NoticeTrigger" do

    before :each do
      allow(employer).to receive(:is_primary_office_local?).and_return(false)
    end

    context "when In eligible renewal application created" do
      subject { Observers::NoticeObserver.new }
      let(:model_event) { ModelEvents::ModelEvent.new(:renewal_application_denied, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.renewal_employer_ineligibility_notice"
          expect(payload[:employer_id]).to eq employer.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        employer.census_employees.non_terminated.each do |ce|
          expect(subject).to receive(:notify) do |event_name, payload|
            expect(event_name).to eq "acapi.info.events.employee.employee_renewal_employer_ineligibility_notice"
            expect(payload[:employee_role_id]).to eq ce.employee_role_id.to_s
            expect(payload[:event_object_kind]).to eq 'PlanYear'
            expect(payload[:event_object_id]).to eq model_instance.id.to_s
          end
        end

        subject.plan_year_update(model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    context "For employee notice" do

      let(:data_elements) {
        [ "employee_profile.notice_date", 
          "employee_profile.first_name", 
          "employee_profile.last_name", 
          "employee_profile.employer_name", 
          "employee_profile.plan_year.current_py_end_date", 
          "employee_profile.plan_year.current_py_end_on + 60.days", 
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

      let(:employee) { employer.census_employees.first }     

      context "when notice event received" do
        subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

        before do
          allow(subject).to receive(:resource).and_return(employee.employee_role)
          allow(subject).to receive(:payload).and_return(payload)
        end

        it "should build the data elements for the notice" do
          current_date = TimeKeeper.date_of_record
          TimeKeeper.set_date_of_record_unprotected!(employer.renewing_plan_year.open_enrollment_end_on.next_day)
          model_instance.advance_date!

          merge_model = subject.construct_notice_object
          expect(merge_model).to be_a(recipient.constantize)
          expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
          expect(merge_model.first_name).to eq employee.first_name
          expect(merge_model.last_name).to eq employee.last_name
          expect(merge_model.employer_name).to eq employer.legal_name
          expect(merge_model.plan_year.current_py_end_date).to eq current_py.end_on.strftime('%m/%d/%Y')
          expect(merge_model.plan_year.current_py_end_on).to eq current_py.end_on
          expect(merge_model.broker_present?).to be_falsey

          TimeKeeper.set_date_of_record_unprotected!(current_date)
        end
      end
    end

    context "For employer notice" do

      let(:data_elements) {
        ["employer_profile.notice_date", 
          "employer_profile.employer_name", 
          "employer_profile.plan_year.renewal_py_oe_end_date", 
          "employer_profile.plan_year.renewal_py_start_date", 
          "employer_profile.plan_year.current_py_end_date", 
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

      context "when notice event received" do
        subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

        before do
          allow(subject).to receive(:resource).and_return(employer)
          allow(subject).to receive(:payload).and_return(payload)
        end

        it "should build the data elements for the notice" do
          
          current_date = TimeKeeper.date_of_record
          TimeKeeper.set_date_of_record_unprotected!(employer.renewing_plan_year.open_enrollment_end_on.next_day)
          model_instance.advance_date!
          merge_model = subject.construct_notice_object

          expect(merge_model).to be_a(recipient.constantize)
          expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
          expect(merge_model.employer_name).to eq employer.legal_name
          expect(merge_model.plan_year.current_py_end_date).to eq current_py.end_on.strftime('%m/%d/%Y')
          expect(merge_model.plan_year.renewal_py_oe_end_date).to eq model_instance.open_enrollment_end_on.strftime('%m/%d/%Y')
          expect(merge_model.plan_year.renewal_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')

          expect(merge_model.plan_year.enrollment_errors).to include(:non_business_owner_enrollment_count)
          if model_instance.start_on.yday != 1
            expect(merge_model.plan_year.enrollment_errors).to include(:enrollment_ratio)
          end

          TimeKeeper.set_date_of_record_unprotected!(current_date)
        end
      end
    end
  end
end