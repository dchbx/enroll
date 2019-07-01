require "rails_helper"

# Our helper slug class so we can use the helper methods in our spec
module SpecHelperClassesForViews
  class InsuredFamiliesHelperSlugForGroupSelectionTermination
    extend Insured::FamiliesHelper
  end
end

RSpec.describe "app/views/insured/group_selection/terminate_confirm.html.erb" do
  context "DCHL ID and Premium" do

    let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :individual_assisted, { household: family.households.first, family: family })}
    let(:benefit_sponsorship) { FactoryBot.create :benefit_sponsors_benefit_sponsorship, :with_benefit_market, :with_organization_cca_profile, :with_initial_benefit_application}
    let(:benefit_application) { benefit_sponsorship.benefit_applications.first }
    let(:employer_profile) { benefit_sponsorship.organization.employer_profile }
    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :with_issuer_profile) }
    let(:employee_names) { ["fname1 sname1", "fname2 sname2"] }

    let(:current_user) {FactoryBot.create(:user)}

    before(:each) do
      allow(hbx_enrollment).to receive(:product).and_return(product)
      allow(hbx_enrollment).to receive(:covered_members_first_names).and_return(employee_names)
      allow(hbx_enrollment).to receive(:total_employee_cost).and_return(100.00)
      @hbx_enrollment = hbx_enrollment
      render :template =>"insured/group_selection/terminate_confirm.html.erb"
    end

    it "should show the DCHL ID as hbx_enrollment.hbx_id" do
      expect(rendered).to match /DCHL ID/
      expect(rendered).to match /#{hbx_enrollment.hbx_id}/
    end

    it "should show the correct Premium" do
      dollar_amount = number_to_currency(SpecHelperClassesForViews::InsuredFamiliesHelperSlugForGroupSelectionTermination.current_premium(hbx_enrollment), precision: 2)
      expect(rendered).to match /Premium/
      expect(rendered).to include dollar_amount
    end
  end
end
