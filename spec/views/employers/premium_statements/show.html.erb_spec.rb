require 'rails_helper'

RSpec.describe "employers/premium_statements/show.html.erb" do
  let(:start_on){ TimeKeeper.date_of_record.beginning_of_month }

  def new_hbx_enrollment
    random_value = rand(999_999_999)
    instance_double(
      "HbxEnrollment",
      plan: new_plan,
      coverage_kind: 'health',
      humanized_dependent_summary: "hds: #{random_value}",
      humanized_members_summary: "hds: #{random_value}",
      total_employer_contribution: "total_employer_contribution:#{random_value}",
      total_employee_cost: "total_employee_cost:#{random_value}",
      total_premium: "total_premium:#{random_value}",
      subscriber: double("subscriber",
                    person: new_person(random_value)
                  ),
      census_employee: new_census_employee,
      benefit_group: new_benefit_group
    )
  end

  def new_person(random_value)
    instance_double(
      "Person",
      employee_roles: employee_roles
    )
  end

  def new_census_employee
    instance_double(
      "CensusEmployee",
      full_name: "My Funny Name",
      ssn: "my funny ssn",
      dob: "my funny dob",
      hired_on: "my funny hired_on",
      published_benefit_group: new_benefit_group
    )
  end

  def new_benefit_group
    instance_double(
      "BenefitGroup",
      title: "My Benefit Group"
    )
  end

  def current_plan_year
    instance_double(
      "PlanYear",
      start_on: start_on
    )
  end

  let(:new_plan) {instance_double("Plan", carrier_profile: new_carrier_profile, name: "my plan 100")}
  let(:new_carrier_profile) {instance_double("CarrierProfile", legal_name: "my legal name")}
  let(:new_employee_role) {instance_double("EmployeeRole", census_employee: new_census_employee)}
  let(:employee_roles) {[new_employee_role, new_employee_role]}
  let(:hbx_enrollments) {[new_hbx_enrollment]}
  let(:employer_profile) {FactoryGirl.create(:employer_profile)}

  before :each do
    assign :current_plan_year, current_plan_year
    assign :hbx_enrollments, hbx_enrollments
    assign :employer_profile, employer_profile
    assign :billing_date, TimeKeeper.date_of_record.beginning_of_month
    allow(view).to receive(:policy_helper).and_return(double("PersonPolicy", updateable?: true, list_enrollments?: true ))
    allow(employer_profile).to receive(:billing_plan_year).and_return([current_plan_year, start_on])
    render :template => "employers/premium_statements/show.html.erb", locals: { employer_profile: employer_profile }
  end

  it "should display billing report of a user" do
    hbx_enrollments.each do |hbx_enrollment|
      census_employee = hbx_enrollment.subscriber.person.employee_roles.first.census_employee
      benefit_group = census_employee.published_benefit_group
      expect(rendered).to match(/#{census_employee.full_name}/)
      expect(rendered).to match(/#{number_to_obscured_ssn(census_employee.ssn)}/)
      expect(rendered).to match(/#{format_date(census_employee.dob)}/)
      expect(rendered).to match(/#{format_date(census_employee.hired_on)}/)
      expect(rendered).to match(/#{benefit_group.title}/)
      expect(rendered).to match(/#{hbx_enrollment.plan.name}/)
      expect(rendered).to match(/#{hbx_enrollment.humanized_members_summary}/)
      expect(rendered).to match(/#{hbx_enrollment.total_employer_contribution}/)
      expect(rendered).to match(/#{hbx_enrollment.total_employee_cost}/)
      expect(rendered).to match(/#{hbx_enrollment.total_premium}/)
    end
  end

end
