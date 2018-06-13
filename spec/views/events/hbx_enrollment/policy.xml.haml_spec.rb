require 'rails_helper'

RSpec.describe "events/hbx_enrollment/policy.haml.erb" do

  let(:plan) { FactoryGirl.build(:plan) }
  let(:census_employee) { FactoryGirl.build(:census_employee, :benefit_group_assignments => [FactoryGirl.build(:benefit_group_assignment)]) }
  let(:employee_role) { FactoryGirl.build(:employee_role, census_employee: census_employee) }
  let(:benefit_group_assignment) { employee_role.census_employee.benefit_group_assignments.first }
  let(:benefit_group) { benefit_group_assignment.benefit_group }
  let(:hbx_enrollment) {  HbxEnrollment.new(plan:plan, employee_role: employee_role, created_at: Time.now) }
  let(:cobra_begin_date) { Date.new(2016,2,1) }

  before :each do
    allow(hbx_enrollment).to receive(:broker_agency_account).and_return(nil)
    allow(hbx_enrollment).to receive(:benefit_group_assignment).and_return(benefit_group_assignment)
    allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
    allow(census_employee).to receive(:cobra_begin_date).and_return(cobra_begin_date)
    allow(hbx_enrollment).to receive(:effective_on).and_return(cobra_begin_date)
    allow(hbx_enrollment).to receive(:cobra_eligibility_date).and_return(cobra_begin_date)
    allow(hbx_enrollment).to receive(:is_cobra_status?).and_return(true)
  end

  it "generates a policy cv with policy, enrollees and plan elements" do
    render :template=>"events/hbx_enrollment/policy", :locals=>{hbx_enrollment: hbx_enrollment}
    expect(rendered).to include("</policy>")
    expect(rendered).to include("<enrollees>")
    expect(rendered).to include("<plan>")
    expect(rendered).to include("<premium_total_amount>")
    expect(rendered).to include("<total_responsible_amount>")
  end


  it "includes the special carrier id" do
    special_plan_id_prefix = Settings.aca.carrier_special_plan_identifier_namespace
    special_plan_id = "abcdefg"
    expected_special_plan_id = special_plan_id_prefix + special_plan_id
    allow(plan).to receive(:carrier_special_plan_identifier).and_return(special_plan_id)
    render :template=>"events/hbx_enrollment/policy", :locals=>{hbx_enrollment: hbx_enrollment}
    expect(rendered).to have_selector("plan id alias_ids alias_id id", :text => expected_special_plan_id)
  end

  context "cobra enrollment" do

    before do
      allow(hbx_enrollment).to receive(:kind).and_return("employer_sponsored_cobra")
      render :template=>"events/hbx_enrollment/policy", :locals=>{hbx_enrollment: hbx_enrollment}
      @doc = Nokogiri::XML(rendered)
    end

    it "should include cobra event type & eligibilty date" do
      expect(@doc.xpath("//x:event_kind", "x"=>"http://openhbx.org/api/terms/1.0").text).to eq "urn:dc0:terms:v1:qualifying_life_event#cobra"
      expect(@doc.xpath("//x:cobra_eligibility_date", "x"=>"http://openhbx.org/api/terms/1.0").text).to eq cobra_begin_date.strftime("%Y%m%d")
    end
  end
end
