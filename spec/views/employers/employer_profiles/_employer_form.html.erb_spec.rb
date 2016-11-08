require "rails_helper"

RSpec.describe "employers/employer_profiles/_employer_form.html.erb" do
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:person) {FactoryGirl.build(:person)}
  let(:organization) {FactoryGirl.build(:organization)}

  before :each do
    allow(organization).to receive(:employer_profile).and_return employer_profile
    allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: false))
    assign(:employer_profile, employer_profile)
    assign(:organization, organization)
    assign(:employer, person)
    render "employers/employer_profiles/employer_form"
  end

  it "should show title" do
    expect(rendered).to match /Business Info/
  end

  it "should show person info" do
    expect(rendered).to match /Employer Information/
    expect(rendered).to match /Point of Contact - Employer Staff/
    expect(rendered).to match  /Last Name/

  end
end
