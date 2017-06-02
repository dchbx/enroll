require 'rails_helper'

RSpec.describe "insured/group_selection/terminate_confirm.html.erb"  do
  let(:employee_role) { FactoryGirl.build(:employee_role) }
  let(:person) { FactoryGirl.build(:person) }
  let(:plan) { FactoryGirl.build(:plan) }
  let(:hbx_enrollment) { HbxEnrollment.new(plan: plan) }
  let(:employer_profile) { double("EmployerProfile", legal_name: "Merge Conflict")}
  let(:family) { Family.new }
  before :each do
    allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return false
    allow(hbx_enrollment).to receive(:may_terminate_coverage?).and_return true
    allow(hbx_enrollment).to receive(:is_shop?).and_return true
    allow(hbx_enrollment).to receive(:coverage_year).and_return(TimeKeeper.date_of_record.year)
    allow(hbx_enrollment).to receive(:employer_profile).and_return(employer_profile)
    assign :change_plan, 'change_plan'
    assign :employee_role, employee_role
    assign :person, person
    assign :family, family
    render "insured/group_selection/enrollment", hbx_enrollment: hbx_enrollment
  end
  it "should show plan contact information" do
    expect(rendered).to have_selector('div',text: 'Plan Contact Info')
  end
  it "should not show carrier contact information" do
    expect(rendered).not_to have_selector('div',text: 'Carrier Contact Info')
  end
end
