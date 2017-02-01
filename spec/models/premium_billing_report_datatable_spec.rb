

  require 'rails_helper'

  describe Effective::Datatables::PremiumBillingReportDataTable do

    context "in one context" do
      let(:employee_role1){
        FactoryGirl.create :employee_role
      }
      let(:plan_year1){
        FactoryGirl.create :plan_year, employer_profile: employee_role1.employer_profile, fte_count: 2, aasm_state: :published
      }

      it "should display no records" do
        d_table = Effective::Datatables::PremiumBillingReportDataTable.new({ id: employee_role1.employer_profile.id, billing_date: plan_year1.open_enrollment_start_on})
        expect(d_table.instance_variable_get(:@hbx_enrollments)).to eq([])
      end
    end

    context "in another context" do
      person = {
        first_name: "Soren",
        last_name: "White",
        dob: "08/13/1979",
        dob_date: "13/08/1979".to_date,
        ssn: "670991234",
        home_phone: "2025551234",
        email: 'soren@dc.gov',
        password: 'aA1!aA1!aA1!',
        legal_name: "Acme Inc.",
        dba: "Acme Inc.",
        fein: rand(999999999)
      }

      let(:employee_role){
        FactoryGirl.create :employee_role
      }
      let(:employee) {
        FactoryGirl.create :census_employee, employer_profile: employee_role.employer_profile,
        first_name: person[:first_name],
        last_name: person[:last_name],
        ssn: person[:ssn],
        dob: person[:dob_date]
      }
  let(:plan_year){
        FactoryGirl.create :plan_year, employer_profile: employee_role.employer_profile, fte_count: 2, aasm_state: :published
      }
  let(:benefit_group){
        FactoryGirl.create :benefit_group, plan_year: plan_year
      }
  ce = CensusEmployee.where(:first_name => /#{person[:first_name]}/i, :last_name => /#{person[:last_name]}/i).first
  let(:person_with_employee_role){
        FactoryGirl.create(:person_with_employee_role, first_name: person[:first_name], last_name: person[:last_name], ssn: person[:ssn], dob: person[:dob_date], census_employee_id: ce.id, employer_profile_id: employer_profile.id, hired_on: ce.hired_on)
      }
  let(:family){
     FactoryGirl.create :family, :with_primary_family_member, person: employee_role.person
   }

  let(:household){
    FactoryGirl.create(:household, family: family)
  }

  let(:benefit_group_assignment){
    FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: employee)

  }

  let(:hbx_enrollment){
    FactoryGirl.create(:hbx_enrollment,
      household: family.active_household,
      coverage_kind: "health",
      effective_on: benefit_group.start_on,
      enrollment_kind: "open_enrollment",
      kind: "employer_sponsored",
      submitted_at: benefit_group.start_on - 20.days,
      benefit_group_id: benefit_group.id,
      employee_role_id: employee_role.id,
      benefit_group_assignment_id: benefit_group_assignment.id,
      plan_id: benefit_group.elected_plan_ids.first
      )
  }

  it "should display records" do
    employee.add_benefit_group_assignment benefit_group, benefit_group.start_on
    query = Queries::EmployerPremiumStatement.new(hbx_enrollment.employer_profile, benefit_group.start_on)
    d_table2 = query.execute.nil? ? [] : query.execute.hbx_enrollments
    expect(d_table2.count).to eq(1)
  end
 end
end
