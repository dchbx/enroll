require 'rails_helper'

RSpec.describe "events/hbx_enrollment/policy.haml.erb" do

  let(:plan) { FactoryGirl.build(:plan) }
  let(:census_employee) { FactoryGirl.build(:census_employee, :benefit_group_assignments => [FactoryGirl.build(:benefit_group_assignment)]) }
  let(:employee_role) { FactoryGirl.build(:employee_role, census_employee: census_employee) }
  let(:benefit_group_assignment) { employee_role.census_employee.benefit_group_assignments.first }
  let(:benefit_group) { benefit_group_assignment.benefit_group }
  let(:hbx_enrollment) {  HbxEnrollment.new(plan:plan, employee_role: employee_role, created_at: Time.now) }

  before :each do
    allow(hbx_enrollment).to receive(:broker_agency_account).and_return(nil)
    allow(hbx_enrollment).to receive(:benefit_group_assignment).and_return(benefit_group_assignment)
    allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
  end

  it "generates a policy cv with policy, enrollees and plan elements" do
    render :template=>"events/hbx_enrollment/policy", :locals=>{hbx_enrollment: hbx_enrollment}
    expect(rendered).to include("</policy>")
    expect(rendered).to include("<enrollees>")
    expect(rendered).to include("<plan>")
    expect(rendered).to include("<premium_total_amount>")
    expect(rendered).to include("<total_responsible_amount>")
  end
end
