require 'rails_helper'

describe "exchanges/hbx_profiles/_cancel_plan_year.html.erb" do
  let(:employer_profile) { FactoryGirl.create(:employer_with_planyear) }

  before :each do
    allow(employer_profile).to receive(:published_plan_year).and_return(employer_profile.plan_years.first)
    @employer_profile = employer_profile
  end

  it "displays cancel form" do
    render template: 'exchanges/hbx_profiles/_cancel_plan_year'
    expect(rendered).to have_text(/Cancelling Plan Year for Employer/)
    expect(rendered).to have_button("Cancel Plan Year")
  end
end