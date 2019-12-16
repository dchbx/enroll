require "rails_helper"

# Our helper slug class so we can use the helper methods in our spec
module SpecHelperClassesForViews
  class InsuredFamiliesHelperSlugForGroupSelectionTermination
    extend Insured::FamiliesHelper
  end
end

RSpec.describe "app/views/insured/group_selection/edit_plan.html.erb" do
  context "Enrollment information and buttons" do

    let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :individual_assisted, { household: family.households.first, family: family, enrollment_members: family.family_members })}
    let(:benefit_sponsorship) { FactoryBot.create :benefit_sponsors_benefit_sponsorship, :with_benefit_market, :with_organization_cca_profile, :with_initial_benefit_application}
    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :with_issuer_profile) }
    let(:qle) { FactoryBot.create(:qualifying_life_event_kind, market_kind:  "individual") }
    let(:sep) {FactoryBot.create(:special_enrollment_period, family: family, qualifying_life_event_kind: qle) }
    let(:current_user) { FactoryBot.create(:user) }

    before(:each) do
      allow(hbx_enrollment).to receive(:product).and_return(product)
      @hbx_enrollment = hbx_enrollment
      @sep = sep
      @family = family
      render :template =>"insured/group_selection/edit_plan.html.erb"
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

    it "should show Cancel Plan button" do
      expect(rendered).to have_selector("a", text: "Cancel Plan",  count: 1)
    end
    #TODO: appearance of shop for plans button & edit edit button

  end
end
