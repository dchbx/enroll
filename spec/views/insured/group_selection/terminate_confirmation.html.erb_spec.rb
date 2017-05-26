require "rails_helper"
include Insured::FamiliesHelper

RSpec.describe "app/views/insured/group_selection/terminate_confirm.html.erb" do
  context "DCHL ID and Premium" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryGirl.build(:hbx_enrollment, :with_enrollment_members, :individual_assisted, { household: family.households.first })}
    let(:plan_year) { FactoryGirl.create(:plan_year, {aasm_state: 'enrolling'}) }
    let(:employer_profile) { plan_year.employer_profile }
    let(:employee_names) { ["fname1 sname1", "fname2 sname2"] }

    let(:current_user) {FactoryGirl.create(:user)}

    before(:each) do
      allow(hbx_enrollment).to receive(:covered_members_first_names).and_return(employee_names)
      @hbx_enrollment = hbx_enrollment
      render :template =>"insured/group_selection/terminate_confirm.html.erb"
    end

    it "should show the DCHL ID as hbx_enrollment.hbx_id" do
      expect(rendered).to match /DCHL ID/
      expect(rendered).to match /#{hbx_enrollment.hbx_id}/
    end

    it "should show the correct Premium" do
      dollar_amount = number_to_currency(current_premium(hbx_enrollment), precision: 2)
      expect(rendered).to match /Premium/
      expect(rendered).to include dollar_amount
    end
  end
end
