require 'rails_helper'

describe "exchanges/hbx_profiles/_cancel_plan_year.html.erb" do
  let(:employer_profile) { FactoryGirl.create(:employer_with_planyear) }

  before :each do
    allow(employer_profile).to receive(:active_plan_year).and_return(employer_profile.plan_years.first)
    @employer_profile = employer_profile
  end

  context "cancel case" do
    it "displays cancel fields" do
      allow_any_instance_of(Exchanges::HbxProfilesHelper).to receive(:can_cancel_employer_plan_year?).with(employer_profile).and_return(true)
      render template: 'exchanges/hbx_profiles/_cancel_plan_year'
      expect(rendered).to have_text(/Cancelling Plan Year for Employer/)
      expect(rendered).to have_button("Cancel Plan Year")
    end
  end

  context "terminate case" do
    it "displays terminate fields" do
      allow_any_instance_of(Exchanges::HbxProfilesHelper).to receive(:can_cancel_employer_plan_year?).with(employer_profile).and_return(false)
      render template: 'exchanges/hbx_profiles/_cancel_plan_year'
      expect(rendered).to have_text(/Terminating Plan Year for Employer/)
      expect(rendered).to have_button("Terminate Plan Year")
    end
  end
end

