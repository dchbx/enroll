require "rails_helper"

RSpec.describe "employers/employer_profiles/my_account/_publish_without_auto_renwals_notice.html.erb" do

  context "Pop Up template" do

    let(:employer_profile) { FactoryGirl.build_stubbed(:employer_profile) }
    let(:plan_year) { FactoryGirl.build_stubbed(:plan_year, employer_profile: employer_profile) }

    before :each do
      assign(:employer_profile, employer_profile)
    end

    it "should have description" do
      render "employers/employer_profiles/my_account/publish_without_auto_renwals_notice", plan_year: plan_year
      expect(rendered).to have_selector("p", text: "Therefore, these employees will actively need to make a new plan selection during the groups open enrollment period or risk being uncovered")
    end
  end
end
