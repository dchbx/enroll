require "rails_helper"

describe "insured/interactive_identity_verifications/failed_validation" do
  let(:mock_response) { instance_double("IdentityVerification::InteractiveVerificationResponse", :transaction_id => "the_transaction_id") }
  let(:current_user) {FactoryGirl.create(:user)}
  before :each do
    allow(view).to receive(:policy_helper).and_return(double('FamilyPolicy', updateable?: true))
    sign_in current_user
  end
  it "should show a message about the user failing validation and providing contact info" do
    assign :verification_response, mock_response
    render :template => "insured/interactive_identity_verifications/failed_validation.html.haml"
    expect(rendered).to include("Your identity could not be confirmed by Experian – the third-party service we use to verify your identity. For your security, you won’t be able to continue your application until you resolve this issue.")
    expect(rendered).to include("Provide your reference number:  the_transaction_id ")
  end

  it "should show a link to invoke fars" do
    assign :verification_response, mock_response
    render :template => "insured/interactive_identity_verifications/failed_validation.html.haml"
    expect(rendered).to include("CONTINUE APPLICATION")
    expect(rendered).to include("href=\"/insured/interactive_identity_verifications/the_transaction_id\"")
    expect(rendered).to include(href= 'https://dchealthlink.com/sites/default/files/v2/forms/DC_Health_Link_Application_for_Health_Coverage_201509.pdf')
    expect(rendered).to include(href='mailto:info@dchealthlink.com')
  end
end