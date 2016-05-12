require "rails_helper"

RSpec.describe "employers/plan_years/_delete_benefit_package_modal.html.erb" do
  let(:employer_profile){ FactoryGirl.create(:employer_profile) }
  let(:plan_year){ FactoryGirl.create(:plan_year, employer_profile: employer_profile) }
  let(:benefit_group){ FactoryGirl.create(:benefit_group, plan_year: plan_year) }

  before(:each) do
    assign(:employer_profile, employer_profile)
  end

  it "it should display confirmation for deleting a benefit package" do
    render partial: "employers/plan_years/delete_benefit_package_modal", locals: { bg: benefit_group, plan_year: plan_year }
    expect(rendered).to match "Are you sure you want to delete benefit package #{benefit_group.title}?"
  end

end
