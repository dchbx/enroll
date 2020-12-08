require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Factories::EmploymentRelationshipFactory, type: :model, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application" do
    let(:renewal_state) { :enrollment_open }
  end

  after :each do
    TimeKeeper.set_date_of_record_unprotected!(TimeKeeper.date_of_record)
  end

  let(:calendar_year) { TimeKeeper.date_of_record.year }
  let(:organization) {
    org = abc_organization
    TimeKeeper.set_date_of_record_unprotected!(TimeKeeper.date_of_record.end_of_year)
    employer_profile = abc_profile
    active_plan_year = predecessor_application
    renewing_plan_year = renewal_application

    benefit_group = predecessor_application.benefit_packages[0]
    renewing_benefit_group = benefit_package

    census_employee = FactoryBot.create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile:benefit_sponsorship.profile, benefit_group: renewing_benefit_group, dob: TimeKeeper.date_of_record - 30.years, hired_on: (TimeKeeper.date_of_record + 2.months).beginning_of_month)

    employer_profile.census_employees.each do |ce|
      ce.add_benefit_group_assignment benefit_group, benefit_group.start_on
      ce.add_renew_benefit_group_assignment([renewing_benefit_group])
      person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name)
      employee_role = FactoryBot.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
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
    TimeKeeper.set_date_of_record_unprotected!(TimeKeeper.date_of_record)
  end
end
