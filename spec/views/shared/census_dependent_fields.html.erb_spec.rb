require 'rails_helper'

describe "shared/census_dependent_fields.html.erb" do
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:census_employee) { CensusEmployee.new }

  before :each do
    helper = Object.new.extend ActionView::Helpers::FormHelper
    helper.extend ActionDispatch::Routing::PolymorphicRoutes
    helper.extend ActionView::Helpers::FormOptionsHelper
    helper.extend ActionView::Context
    census_dependent = census_employee.census_dependents.build
    mock_form = ActionView::Helpers::FormBuilder.new(:census_dependent, census_dependent, helper, {})
    render "shared/census_dependent_fields", :f => mock_form
  end

  it "should have two radio options" do
    expect(rendered).to have_selector("input[type='radio']", count: 2)
  end

  it "should not have checked checkbox option" do
    expect(rendered).to have_selector("input[checked='checked']", count: 0)
  end
end
