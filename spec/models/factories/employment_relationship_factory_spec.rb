require 'rails_helper'

RSpec.describe Factories::EmploymentRelationshipFactory, type: :model, dbclean: :after_each do
  
  let(:calender_year) { TimeKeeper.date_of_record.year }
  let(:organization) { 
    org = FactoryGirl.create :organization, legal_name: "Corp 1" 
    employer_profile = FactoryGirl.create :employer_profile, organization: org
    active_plan_year = FactoryGirl.create :plan_year, employer_profile: employer_profile, aasm_state: :active, :start_on => Date.new(calender_year - 1, 5, 1), :end_on => Date.new(calender_year, 4, 30),
    :open_enrollment_start_on => Date.new(calender_year - 1, 4, 1), :open_enrollment_end_on => Date.new(calender_year - 1, 4, 10), fte_count: 5
    renewing_plan_year = FactoryGirl.create :plan_year, employer_profile: employer_profile, aasm_state: :renewing_enrolling, :start_on => Date.new(calender_year, 5, 1), :end_on => Date.new(calender_year+1, 4, 30),
    :open_enrollment_start_on => Date.new(calender_year, 4, 1), :open_enrollment_end_on => Date.new(calender_year, 4, 10), fte_count: 5 
    benefit_group = FactoryGirl.create :benefit_group, plan_year: active_plan_year, effective_on_kind: "date_of_hire"
    renewing_benefit_group = FactoryGirl.create :benefit_group, plan_year: renewing_plan_year
    census_employee = FactoryGirl.create :census_employee, employer_profile: employer_profile, dob: TimeKeeper.date_of_record - 30.years, hired_on: Date.new(calender_year, 3, 12)
    
    employer_profile.census_employees.each do |ce| 
      ce.add_benefit_group_assignment benefit_group, benefit_group.start_on
      ce.add_renew_benefit_group_assignment(renewing_benefit_group)
      person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
      employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
      ce.update_attributes({employee_role: employee_role})
      family = Family.find_or_build_from_employee_role(employee_role)
    end

    org
  }

  it "should display the effective on date as date of hire" do
    census_employee = organization.employer_profile.census_employees.where(dob: TimeKeeper.date_of_record - 30.years).first
    person = census_employee.employee_role.person
    employee_candidate = Forms::EmployeeCandidate.new(user_id: person.id)
    employment_relationship = Factories::EmploymentRelationshipFactory.new
    employmentrelationship = employment_relationship.build(employee_candidate, census_employee)
    expect(employmentrelationship.eligible_for_coverage_on).to eq census_employee.hired_on
  end
end