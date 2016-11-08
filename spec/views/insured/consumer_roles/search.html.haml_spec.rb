require "rails_helper"

RSpec.describe "insured/consumer_roles/search.html.haml" do

  let(:person) { FactoryGirl.create(:person) }
  let(:current_user) { FactoryGirl.create(:user, person: person) }

  before :each do
    sign_in current_user
    assign(:person, Forms::ConsumerCandidate.new)
    allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: true))
    render template: "insured/consumer_roles/search.html.haml"
  end

  it "should display the title" do
    expect(rendered).to have_selector('h1', text: 'Personal Information')
  end

  it "should have memo to indicate required fields" do
    expect(rendered).to have_selector('p.memo', text: '* = required field')
  end

end
