require "rails_helper"

describe "insured/interactive_identity_verifications/service_unavailable" do
  let(:person) { FactoryGirl.create(:person) }
  let(:consumer_role) { FactoryGirl.create(:consumer_role) }
  let(:current_user) {FactoryGirl.create(:user)}
  before :each do
    assign(:person, person)
    assign(:consumer_role, consumer_role)
    allow(consumer_role).to receive(:person).and_return person
    allow(person).to receive(:consumer_role).and_return consumer_role
    sign_in current_user
    allow(view).to receive(:policy_helper).and_return(double('FamilyPolicy', updateable?: true))
  end
  it "should show a message about the service being down and asking the user to try back later" do
    render :template => "insured/interactive_identity_verifications/service_unavailable.html.haml"
    expect(rendered).to include("We’re sorry. Experian - the third-party service we use to confirm your identity - is unavailable. Please try again later.")
  end
end
