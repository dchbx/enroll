require "rails_helper"
include ActionView::Context
RSpec.describe "insured/consumer_roles/_form.html.erb" do
  let(:person) { Person.new }
  let(:current_user) {FactoryGirl.create(:user)}

  #before do
    #Translation.create(key: "en.required_field", value: "\"required field\"")
  #end

  before :each do
    helper = Object.new.extend ActionView::Helpers::FormHelper
    helper.extend ActionDispatch::Routing::PolymorphicRoutes
    helper.extend ActionView::Helpers::FormOptionsHelper
    person.build_consumer_role if person.consumer_role.blank?
    person.consumer_role.build_nested_models_for_person
    mock_form = ActionView::Helpers::FormBuilder.new(:person, person, helper, {})
    stub_template "shared/_consumer_fields.html.erb" => ''
    sign_in current_user
    allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: true))
    assign(:consumer_role, person.consumer_role)
    assign(:person, person)
    render partial: "insured/consumer_roles/form", locals: {f: mock_form}
  end

  it "should have title" do
    expect(rendered).to match /Personal Information/
  end

  it "should display hint for asterisks" do
    expect(rendered).to have_selector('p.memo', text: '* = required field')
  end

  it "should display only one no_dc_address" do
    expect(rendered).to have_selector('input#no_dc_address', count: 1)
  end

  it "should display the is_applying_coverage field option" do
    expect(rendered).to match /Is this person applying for coverage?/
  end

  it "should display the affirmative message" do
    expect(rendered).to match /Even if you don’t want health coverage for yourself, providing your SSN can be helpful since it can speed up the application process. We use SSNs to check income and other information to see who’s eligible for help with health coverage costs./
  end
end
