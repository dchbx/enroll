require 'rails_helper'
include Insured::FamiliesHelper

RSpec.describe "insured/group_selection/_enrollment.html.erb" do
  let(:employee_role) { FactoryGirl.build(:employee_role) }
  let(:person) { FactoryGirl.build(:person) }
  let(:plan) { FactoryGirl.build(:plan) }
  let(:benefit_group) { FactoryGirl.build(:benefit_group) }
  let(:hbx_enrollment) { HbxEnrollment.new(plan: plan, benefit_group: benefit_group) }
  let(:family) { Family.new }
  before :each do
    allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
    allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return false
    allow(hbx_enrollment).to receive(:may_terminate_coverage?).and_return true
    allow(hbx_enrollment).to receive(:is_shop?).and_return true
    #allow(hbx_enrollment).to receive(:coverage_year).and_return 2016
    assign :change_plan, 'change_plan'
    assign :employee_role, employee_role
    assign :person, person
    assign :family, family
    render "insured/group_selection/enrollment", hbx_enrollment: hbx_enrollment
  end

  it 'should have title' do
    title = "#{hbx_enrollment.coverage_year} #{plan.coverage_kind.capitalize} Coverage"
    expect(rendered).to have_content(title)
  end

  it "should have the link of terminate" do
    expect(rendered).to have_selector('a', text: 'Terminate Plan')
  end

  it "should have terminate date" do
    expect(rendered).to have_selector('label', text: 'Termination date: ')
  end

  it "should not have button of change plan" do
    expect(rendered).not_to have_selector('a', text: 'Change Plan')
  end

  it "should show plan contact information" do
    expect(rendered).to have_selector('div',text: 'Plan Contact Info')
  end
  it "should not show carrier contact information" do
    expect(rendered).not_to have_selector('div',text: 'Carrier Contact Info')
  end

  it "should show the DCHL ID as hbx_enrollment.hbx_id" do
    expect(rendered).to match /DCHL ID/
    expect(rendered).to match /#{hbx_enrollment.hbx_id}/
  end

  it "should show the correct Premium" do
    dollar_amount = number_to_currency(current_premium(hbx_enrollment), precision: 2)
    expect(rendered).to match /Premium/
    expect(rendered).to include dollar_amount
  end
end
