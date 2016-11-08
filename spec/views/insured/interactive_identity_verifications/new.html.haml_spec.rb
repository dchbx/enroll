require "rails_helper"

describe "insured/interactive_identity_verifications/new" do
  let(:mock_response) { IdentityVerification::InteractiveVerification::Response.new(:response_id => "2343", :response_text => "Response A") }
  let(:mock_question) { IdentityVerification::InteractiveVerification::Question.new(:question_id => "1", :question_text => "first_question_text", :responses => [mock_response]) }
  let(:mock_verification) { IdentityVerification::InteractiveVerification.new(:questions => [mock_question]) }
  let(:current_user) {FactoryGirl.create(:user)}
  before :each do
    allow(view).to receive(:policy_helper).and_return(double('FamilyPolicy', updateable?: true))
    sign_in current_user
    assign :interactive_verification, mock_verification
  end

  it "should render a form for the questions" do
    render :template => "insured/interactive_identity_verifications/new.html.haml"
    expect(rendered).to have_selector("form")
  end
end
