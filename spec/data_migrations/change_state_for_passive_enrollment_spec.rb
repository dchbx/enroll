require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_state_for_passive_enrollment")
describe ChangeStateForPassiveEnrollment do
  let(:calender_year) { TimeKeeper.date_of_record.year }
  let(:given_task_name) { "deactivate_consumer_role" }
  subject { ChangeStateForPassiveEnrollment.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing passive enrollment aasm state" do
    let(:organization) { 
      org = FactoryGirl.create :organization, legal_name: "Corp 1" 
      employer_profile = FactoryGirl.create :employer_profile, organization: org
      renewing_plan_year = FactoryGirl.create :plan_year, employer_profile: employer_profile, aasm_state: :renewing_enrolled, :start_on => Date.new(calender_year, 5, 1), :end_on => Date.new(calender_year+1, 4, 30),
      :open_enrollment_start_on => Date.new(calender_year, 4, 1), :open_enrollment_end_on => Date.new(calender_year, 4, 10), fte_count: 5 
      renewing_benefit_group = FactoryGirl.create :benefit_group, :with_valid_dental, plan_year: renewing_plan_year
      census_employee = FactoryGirl.create :census_employee, employer_profile: employer_profile, dob: TimeKeeper.date_of_record - 30.years
      employer_profile.census_employees.each do |census_employee| 
        census_employee.add_renew_benefit_group_assignment(renewing_benefit_group)
        person = FactoryGirl.create(:person, last_name: census_employee.last_name, first_name: census_employee.first_name)
        employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: census_employee, employer_profile: employer_profile)
        census_employee.update_attributes({:employee_role =>  employee_role })
        family = Family.find_or_build_from_employee_role(employee_role)

        enrollment_one = HbxEnrollment.create_from(
          employee_role: employee_role,
          coverage_household: family.households.first.coverage_households.first,
          benefit_group_assignment: census_employee.renewal_benefit_group_assignment,
          benefit_group: renewing_benefit_group,
          )
        enrollment_one.update_attributes(:aasm_state => 'coverage_selected', coverage_kind: "dental")

        enrollment_two = HbxEnrollment.create_from(
          employee_role: employee_role,
          coverage_household: family.households.first.coverage_households.first,
          benefit_group_assignment: census_employee.renewal_benefit_group_assignment,
          benefit_group: renewing_benefit_group,
          )
        enrollment_two.update_attributes(:aasm_state => 'coverage_canceled', coverage_kind: "health")
      end

    }

    it "should change the passive enrollment aasm state" do
      employer_profile = organization.first.employer_profile
      census_employee = employer_profile.census_employees.first
      renewing_plan_year = organization.first.employer_profile.plan_years.last
      enrollment = census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.last
      expect(enrollment.aasm_state).to eq "coverage_canceled"
      subject.migrate
      enrollment.reload
      expect(enrollment.aasm_state).to eq "coverage_enrolled"
    end

    it "should not change the passive enrollment aasm state" do
      employer_profile = organization.first.employer_profile
      census_employee = employer_profile.census_employees.first
      renewing_plan_year = organization.first.employer_profile.plan_years.last
      enrollment = census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.last
      enrollment.update_attribute(:coverage_kind, "dental")
      expect(enrollment.aasm_state).to eq "coverage_canceled"
      subject.migrate
      enrollment.reload
      expect(enrollment.aasm_state).to eq "coverage_canceled"
    end
  end
end
