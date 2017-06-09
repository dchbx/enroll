require 'rails_helper'

describe "exchanges/hbx_profiles/_reinstate_plan_year.html.erb_spec.rb" do
  let(:employer_profile) { FactoryGirl.create(:employer_with_planyear) }

  before :each do
    allow_any_instance_of(Exchanges::HbxProfilesHelper).to receive(:latest_terminated_plan_year).and_return(employer_profile.plan_years.first)
    @employer_profile = employer_profile
  end

  it "displays reinstate plan year form" do
    render template: 'exchanges/hbx_profiles/_reinstate_plan_year'
    expect(rendered).to have_text(/Reinstate Plan Year for Employer/)
    expect(rendered).to have_button("Reinstate Plan Year")
  end
end