require 'rails_helper'

describe "shared/_home_address_fields.html.erb" do
  let(:person) { FactoryBot.build(:person) }

  before :each do
    helper = Object.new.extend ActionView::Helpers::FormHelper
    helper.extend ActionDispatch::Routing::PolymorphicRoutes
    helper.extend ActionView::Helpers::FormOptionsHelper
    #person.addresses.new(kind: 'home')
    mock_form = ActionView::Helpers::FormBuilder.new(:person, person, helper, {})
    render "shared/home_address_fields", :f => mock_form
  end

  it "should have address info" do
    # expect(rendered).to match /NEW ADDRESS/
    # expect(rendered).to have_selector("label", text: "Home Address")
  end

  it "should not have delete option" do
    expect(rendered).not_to have_selector("a.close-2")
  end
end
