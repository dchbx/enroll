require 'rails_helper'

RSpec.describe Factories::CensusEmployeeFactory, type: :model, dbclean: :after_each do

  context "When Census Employe don't have benefit group assignment" do 
    let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month - 1.year}
    let!(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'active' ) }
    let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") } 
    let!(:census_employee) { FactoryGirl.create(:census_employee, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789', hired_on: TimeKeeper.date_of_record, employer_profile: employer_profile) }
    let!(:person) { FactoryGirl.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789') }  
    let!(:shop_family)       { FactoryGirl.create(:family, :with_primary_family_member, :person => person) }
    let!(:renewal_plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on + 1.year, :aasm_state => 'renewing_draft' ) }
    let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: renewal_plan_year, title: "Benefits #{renewal_plan_year.start_on.year}") }

    it 'should set default benefit group assignment with given plan year' do
      expect(census_employee.active_benefit_group_assignment.benefit_group).to eq active_benefit_group
      census_employee_factory = Factories::CensusEmployeeFactory.new
      census_employee_factory.plan_year = renewal_plan_year
      census_employee_factory.census_employee = census_employee
      census_employee_factory.begin_coverage
      expect(census_employee.active_benefit_group_assignment.benefit_group).to eq renewal_benefit_group
    end
  end
  
  context "When ER offers both health and dental in a plan year" do 
    let(:calender_year) { TimeKeeper.date_of_record.year }
    let(:organization) { 
      org = FactoryGirl.create :organization, legal_name: "Corp 1" 
      employer_profile = FactoryGirl.create :employer_profile, organization: org
      active_plan_year = FactoryGirl.create :plan_year, employer_profile: employer_profile, aasm_state: :active, :start_on => Date.new(calender_year - 1, 5, 1), :end_on => Date.new(calender_year, 4, 30),
      :open_enrollment_start_on => Date.new(calender_year - 1, 4, 1), :open_enrollment_end_on => Date.new(calender_year - 1, 4, 10), fte_count: 5
      renewing_plan_year = FactoryGirl.create :plan_year, employer_profile: employer_profile, aasm_state: :renewing_enrolled, :start_on => Date.new(calender_year, 5, 1), :end_on => Date.new(calender_year+1, 4, 30),
      :open_enrollment_start_on => Date.new(calender_year, 4, 1), :open_enrollment_end_on => Date.new(calender_year, 4, 10), fte_count: 5 
      benefit_group = FactoryGirl.create :benefit_group, :with_valid_dental, plan_year: active_plan_year
      renewing_benefit_group = FactoryGirl.create :benefit_group, :with_valid_dental, plan_year: renewing_plan_year
      owner = FactoryGirl.create :census_employee, :owner, employer_profile: employer_profile
      2.times{|i| FactoryGirl.create :census_employee, employer_profile: employer_profile, dob: TimeKeeper.date_of_record - 30.years + i.days }
      employer_profile.census_employees.each do |ce| 
        ce.add_benefit_group_assignment benefit_group, benefit_group.start_on
        ce.add_renew_benefit_group_assignment(renewing_benefit_group)
        person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
        employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
        ce.update_attributes({:employee_role =>  employee_role })
        family = Family.find_or_build_from_employee_role(employee_role)

        enrollment_one = HbxEnrollment.create_from(
          employee_role: employee_role,
          coverage_household: family.households.first.coverage_households.first,
          benefit_group_assignment: ce.renewal_benefit_group_assignment,
          benefit_group: renewing_benefit_group,
          )
        enrollment_one.update_attributes(:aasm_state => 'coverage_selected', coverage_kind: "dental")

        enrollment_two = HbxEnrollment.create_from(
          employee_role: employee_role,
          coverage_household: family.households.first.coverage_households.first,
          benefit_group_assignment: ce.renewal_benefit_group_assignment,
          benefit_group: renewing_benefit_group,
          )
        enrollment_two.update_attributes(:aasm_state => 'auto_renewing', coverage_kind: "health")
      end

      org
    }

    it "should have these statuses" do
      employer_profile = organization.employer_profile
      census_employee = employer_profile.census_employees.first
      renewing_plan_year = organization.employer_profile.plan_years.last
      employer_profile.census_employees.each do |census_employee|
        enrollment_one = census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.first
        enrollment_two = census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.last
        expect(enrollment_one.aasm_state).to eq "coverage_selected"
        expect(enrollment_two.aasm_state).to eq "auto_renewing"
      end
    end

    it "should transit to coverage_enrolled status for both enrollments" do
      employer_profile = organization.employer_profile
      census_employee = employer_profile.census_employees.first
      renewing_plan_year = organization.employer_profile.plan_years.last
      subject = Factories::CensusEmployeeFactory.new
      employer_profile.census_employees.each do |census_employee|
        enrollment_one = census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.first
        enrollment_two = census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.last
        subject.census_employee = census_employee
        subject.plan_year = renewing_plan_year
        subject.begin_coverage
        expect(enrollment_one.aasm_state).to eq "coverage_enrolled"
        expect(enrollment_two.aasm_state).to eq "coverage_enrolled"
      end
    end

    it "should transit to coverage_canceled status for both one and coverage_enrolled for other" do
      employer_profile = organization.employer_profile
      census_employee = employer_profile.census_employees.first
      renewing_plan_year = organization.employer_profile.plan_years.last
      subject = Factories::CensusEmployeeFactory.new
      employer_profile.census_employees.each do |census_employee|
        enrollment_one = census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.first
        enrollment_two = census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.last
        enrollment_two.update_attribute(:coverage_kind, "dental")
        subject.census_employee = census_employee
        subject.plan_year = renewing_plan_year
        subject.begin_coverage
        expect(enrollment_one.aasm_state).to eq "coverage_enrolled"
        expect(enrollment_two.aasm_state).to eq "coverage_canceled"
      end
    end

    it "should transit to coverage_canceled status for both one and coverage_enrolled for other" do
      employer_profile = organization.employer_profile
      census_employee = employer_profile.census_employees.first
      renewing_plan_year = organization.employer_profile.plan_years.last
      subject = Factories::CensusEmployeeFactory.new
      employer_profile.census_employees.each do |census_employee|
        enrollment_one = census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.first
        enrollment_two = census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.last
        enrollment_two.update_attribute(:coverage_kind, "dental")
        subject.census_employee = census_employee
        subject.plan_year = renewing_plan_year
        subject.begin_coverage
        expect(enrollment_one.aasm_state).to eq "coverage_enrolled"
        expect(enrollment_two.aasm_state).to eq "coverage_canceled"
      end
    end
  end
end
