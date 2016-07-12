require 'rails_helper'

RSpec.describe "insured/group_selection/_enrollment.html.erb"  do
  let(:employee_role) { FactoryGirl.build(:employee_role) }
  let(:person) { FactoryGirl.build(:person) }
  let(:plan) { FactoryGirl.build(:plan) }
  let(:hbx_enrollment) { HbxEnrollment.new(plan: plan) }
  before :each do
    allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return false
    allow(hbx_enrollment).to receive(:may_terminate_coverage?).and_return true
    assign :change_plan, 'change_plan'
    assign :employee_role, employee_role
    assign :person, person
    render "insured/group_selection/enrollment", hbx_enrollment: hbx_enrollment
  end

  it 'should have title' do
    expect(rendered).to have_selector('h4', text: "#{plan.active_year} #{plan.coverage_kind.capitalize} Coverage DCHL")
  end

  it "should have the link of terminate" do
    expect(rendered).to have_selector('a', text: 'Terminate Plan')
    expect(rendered).to have_selector("a[href='#{purchase_insured_families_path(change_plan: 'change_plan', terminate: 'terminate', hbx_enrollment_id: hbx_enrollment.id)}']")
  end
end
