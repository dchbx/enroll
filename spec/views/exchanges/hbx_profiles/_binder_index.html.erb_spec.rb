require 'rails_helper'

RSpec.describe "exchanges/hbx_profiles/_binder_index.html.erb" do

  let(:new_plan_year){
    instance_double(
      "PlanYear",
      additional_required_participants_count: 0
    )
  }

  let(:renewing_plan_year){
    instance_double(
      "PlanYear",
      additional_required_participants_count: 2
    )
  }

  let(:new_employer){
    instance_double(
      "EmployerProfile",
      id: "new_id",
      legal_name: "test employer new",
      aasm_state: "enrolling",
      show_plan_year: new_plan_year,
      is_new_employer?: true,
      is_renewing_employer?: false,
      renewing_plan_year: false
    )
  }

  let(:organization_1){
    instance_double(
      "Organization",
      legal_name: "test employer new",
      employer_profile: new_employer
      )
  }

  let(:organization_2){
    instance_double(
      "Organization",
      legal_name: "test employer new",
      employer_profile: renewing_employer
      )
  }

  let(:renewing_employer){
    instance_double(
      "EmployerProfile",
      id: "renewing_id",
      legal_name: "test employer renewing",
      aasm_state: "renewing_enrolling",
      show_plan_year: renewing_plan_year,
      is_renewing_employer?: true,
      is_new_employer?: false,
      renewing_plan_year: true
    )
  }

  let(:organizations){ [organization_1, organization_2] }

  before :each do
    assign(:organizations, organizations)
    allow(new_plan_year).to receive(:assigned_census_employees_without_owner).and_return(true)
    allow(renewing_plan_year).to receive(:assigned_census_employees_without_owner).and_return(true)
  end

  it "should match new employer information" do
    allow(renewing_employer).to receive(:is_renewing_employer?).and_return(false)
    render partial: "exchanges/hbx_profiles/binder_index"
    expect(rendered).to match(/#{new_employer.legal_name}/)
    expect(rendered).to match(/#{new_employer.aasm_state.titleize}/)
    expect(rendered).to match(/New/)
    expect(rendered).not_to match(/#{renewing_employer.legal_name}/)
    expect(rendered).not_to match(/#{renewing_employer.aasm_state}/)
  end

  it "should match existing employer information" do
    allow(new_employer).to receive(:is_new_employer?).and_return(false)
    render partial: "exchanges/hbx_profiles/binder_index"
    expect(rendered).to match(/#{renewing_employer.legal_name}/)
    expect(rendered).to match(/#{renewing_employer.aasm_state.titleize}/)
    expect(rendered).to match(/Renewing/)
    expect(rendered).not_to match(/#{new_employer.legal_name}/)
  end

end
