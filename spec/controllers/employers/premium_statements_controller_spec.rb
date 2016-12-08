require 'rails_helper'

RSpec.describe Employers::PremiumStatementsController do
  let(:user) { double("User") }
  let(:person) { FactoryGirl.create(:person)}
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:current_plan_year) { double("PlanYear", enrolled: []) }
  let(:subscriber) { double("HbxEnrollmentMember") }
  let(:carrier_profile){ double("CarrierProfile", legal_name: "my legal name") }
  let(:employee_roles) { [double("EmployeeRole")] }
  let(:benefit_group){ double("BenefitGroup", title: "my benefit group") }

  let(:plan){ double(
    "Plan",
    name: "my plan",
    carrier_profile: carrier_profile,
    coverage_kind: "my coverage kind"
    ) }

  let(:hbx_enrollments) { [
    double("HbxEnrollment",
      plan: plan,
      humanized_members_summary: 2,
      total_employer_contribution: 200,
      total_employee_cost: 781.2,
      total_premium: 981.2,
      )] }

  let(:census_employee) {
    double("CensusEmployee",
      full_name: "my full name",
      ssn: "my ssn",
      dob: "my dob",
      hired_on: "my hired_on",
      published_benefit_group: benefit_group
      )
  }

  context "GET show" do

    before do
      allow(user).to receive(:person).and_return(person)
      allow(EmployerProfile).to receive(:find).and_return(employer_profile)
      allow(employer_profile).to receive(:enrollments_for_billing).and_return(hbx_enrollments)
      allow(census_employee).to receive(:is_active?).and_return(true)
      hbx_enrollments.each do |hbx_enrollment|
        allow(hbx_enrollment).to receive(:census_employee).and_return(census_employee)
      end
    end

    it "should return contribution" do
      sign_in(user)
      xhr :get, :show, id: "test"
      expect(response).to have_http_status(:success)
    end
  end

end