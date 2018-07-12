require 'rails_helper'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
RSpec.describe "insured/plan_shoppings/_individual_agreement.html.erb" do
  let(:person) { double(first_name: 'jack', last_name: 'white') }
  let(:hbx_enrollment) do
    instance_double(
      "HbxEnrollment", id: "hbx enrollment id"
    )
  end
  before :each do
    assign(:person, person)
    assign(:hbx_enrollment, hbx_enrollment)
    render "insured/plan_shoppings/individual_agreement"
  end

  it "should display the title" do
    expect(rendered).to have_selector('h3', text: "Terms and Conditions")
  end

  it "should have required fields" do
    expect(rendered).to have_selector("input[placeholder='First Name *']")
    expect(rendered).to have_selector("input[placeholder='Last Name *']")
  end

  it "should have two hidden fields for first and last name" do
    expect(rendered).to have_selector("input[value='jack']")
    expect(rendered).to have_selector("input[value='white']")
  end
end
end
