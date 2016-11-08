require "rails_helper"

RSpec.describe "employers/employer_profiles/my_account/_index_table.html.erb" do
  let(:employer_profile_a) { FactoryGirl.create(:employer_profile) }
  let(:employer_profile_b) { FactoryGirl.create(:employer_profile) }

  before :each do
    assign(:employer_profiles, [employer_profile_a, employer_profile_b])
    allow(view).to receive(:policy_helper).and_return(double("EmployerProfilePolicy", updateable?: true, list_enrollments?: true))
    render "employers/employer_profiles/index_table"
  end

  it "should display a link to the Enrollment Report for employer profile a" do
    expect(rendered).to match(/#{employers_premium_statement_path(employer_profile_a)}/)
  end

  it "should display a link to the Enrollment Report for employer profile b" do
    expect(rendered).to match(/#{employers_premium_statement_path(employer_profile_b)}/)
  end
end
