require 'rails_helper'

RSpec.describe "_help_signup.html.erb" do

  it "should have button with text 'Help Me Sign Up'" do
    allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: true))
    render "insured/families/help_signup"
    expect(rendered).to have_content "Help Me Sign Up"
    expect(rendered).not_to have_selector('.blocking')
  end
  it "should have button with text 'Help Me Sign Up' blocked if not updateable" do
    allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: false))
    render "insured/families/help_signup"
    expect(rendered).to have_selector('.blocking', text: "Help Me Sign Up")
  end

end
