require 'rails_helper'

describe 'ModelEvents::EmployeeTerminationNoticeToEmployee', :dbclean => :after_each do

  let(:notice_event) { "employee_notice_for_employee_terminated_from_roster" }
  let!(:termination_date) {(TimeKeeper.date_of_record)}
  let(:start_on) { (TimeKeeper.date_of_record - 2.months).beginning_of_month }
  let!(:employer) { create(:employer_with_planyear, start_on: start_on, plan_year_state: 'active') }
  let(:plan_year) { build(:plan_year, employer_profile: employer, start_on: start_on, aasm_state: 'active', benefit_groups: [benefit_group]) }
  let!(:census_employee){ FactoryGirl.create(:census_employee, employer_profile: employer)  }
  let!(:person)  {FactoryGirl.create(:person, last_name: census_employee.last_name, first_name: census_employee.first_name)}
  let!(:employee_role) { FactoryGirl.create(:employee_role, person: person, census_employee: census_employee, employer_profile: employer) }

  let(:enrollment)   { FactoryGirl.create(:hbx_enrollment,
                                          household: census_employee.employee_role.person.primary_family.active_household,
                                          coverage_kind: "health",
                                          terminated_on: termination_date,
                                          kind: "employer_sponsored",
                                          benefit_group_id: census_employee.employer_profile.plan_years.where(aasm_state: 'active').first.benefit_groups.first.id,
                                          employee_role_id: census_employee.employee_role.id,
                                          benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
                                          
  )
  }
  let(:benefit_group) { FactoryGirl.create(:benefit_group) }
  let!(:benefit_group_assign) { double("BenefitGroupAssign")}


before do
    census_employee.update_attributes({employee_role: employee_role})
    family = Family.find_or_build_from_employee_role(employee_role)
    census_employee
    census_employee.terminate_employment(termination_date)
    census_employee.save!
end

  describe "NoticeTrigger" do
    context "when employee terminated from the roster" do
      subject { Observers::NoticeObserver.new }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.employee_notice_for_employee_terminated_from_roster"
          expect(payload[:employee_role_id]).to eq census_employee.employee_role.id.to_s
          expect(payload[:event_object_kind]).to eq 'CensusEmployee'
          expect(payload[:event_object_id]).to eq census_employee.id.to_s
        end
        subject.deliver(recipient: census_employee.employee_role, event_object: census_employee, notice_event: "employee_notice_for_employee_terminated_from_roster")
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
          "employee_profile.notice_date",
          "employee_profile.employer_name",
          "employee_profile.first_name",
          "employee_profile.last_name",
          "employee_profile.termination_of_employment",
          "employee_profile.broker.primary_fullname",
          "employee_profile.broker.organization",
          "employee_profile.broker.phone",
          "employee_profile.broker.email",
          "employee_profile.broker_present?"
      ]
    }

    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "CensusEmployee",
        "event_object_id" => census_employee.id
    } }

    context "when notice event received" do
      before do
        allow_any_instance_of(BenefitGroupAssignment).to receive(:hbx_enrollment).and_return(enrollment)
        allow_any_instance_of(CensusEmployee).to receive(:benefit_group_assignments).and_return(benefit_group_assign)
        allow(census_employee).to receive_message_chain(:published_benefit_group_assignment,:hbx_enrollments,:select).and_return([enrollment])
        allow(benefit_group_assign).to receive(:hbx_enrollments).and_return([enrollment])
        allow(subject).to receive(:resource).and_return(employee_role)
        allow(subject).to receive(:payload).and_return(payload)
      end
      
      it "should retrun merge mdoel" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employee first name" do
        expect(merge_model.first_name).to eq census_employee.employee_role.person.first_name
      end

      it "should return employee last name" do
        expect(merge_model.last_name).to eq census_employee.employee_role.person.last_name
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq census_employee.employer_profile.legal_name
      end

      it "should return termination of employement" do
        expect(merge_model.termination_of_employment).to eq census_employee.employment_terminated_on.strftime('%m/%d/%Y')
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end
end