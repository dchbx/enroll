require "rails_helper"

RSpec.describe "employers/employer_profiles/_billing.html.erb" do
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }

  before :each do
    assign(:employer_profile, employer_profile)
    render "employers/employer_profiles/my_account/billing"
  end

  it "should display the employer profile hbx_id" do
    expect(rendered).to match employer_profile.hbx_id.upcase
  end

end
