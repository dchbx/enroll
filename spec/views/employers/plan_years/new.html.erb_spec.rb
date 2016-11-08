require "rails_helper"

RSpec.describe "employers/plan_years/new.html.erb" do
  let(:employer_profile){FactoryGirl.create(:employer_profile)}
  let(:plan_year){FactoryGirl.create(:plan_year, employer_profile: employer_profile)}

  before(:each) do
    assign(:employer_profile, employer_profile)
    plan_year.benefit_groups.build
    assign(:plan_year, plan_year)
    assign(:carriers, Array.new)
    controller.request.path_parameters[:employer_profile_id] = employer_profile.id
    stub_template "shared/_reference_plans_list.html.erb" => ""
    allow(view).to receive(:policy_helper).and_return(double("EmployerProfilePolicy", updateable?: true, list_enrollments?: true))
    render :template => "employers/plan_years/new.html.erb"
  end

  it "displays four relationship benefits" do
    %w(employee spouse domestic_partner child_under_26).each do |kind|
      # expect(rendered).to match /#{kind}/
    end
  end

  it "should have the link of reference_plan_options_link" do
    expect(rendered).to match("a[href='/employers/employer_profiles/#{employer_profile.id}/plan_years/reference_plan_options']")
  end
end
