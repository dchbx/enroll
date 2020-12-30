require "rails_helper"

# Our helper slug class so we can use the helper methods in our spec
module SpecHelperClassesForViews
  class InsuredFamiliesHelperSlugForGroupSelectionTermination
    extend Insured::FamiliesHelper
  end
end

RSpec.describe "app/views/insured/group_selection/edit_plan.html.erb" do
  context "Enrollment information and buttons" do

    let(:current_user) { FactoryBot.create(:user) }
    let!(:person) {FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
    let!(:family) {FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person)}
    let(:sep) {FactoryBot.create(:special_enrollment_period, family: family)}
    let!(:hbx_enrollment) {FactoryBot.create(:hbx_enrollment, :individual_assisted, family: family, product: @product, consumer_role_id: person.consumer_role.id)}
    let!(:hbx_enrollment_member1) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, is_subscriber: true, eligibility_date: (TimeKeeper.date_of_record - 10.days), hbx_enrollment: hbx_enrollment)}
    let!(:hbx_enrollment_member2) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[1].id, eligibility_date: (TimeKeeper.date_of_record - 10.days), hbx_enrollment: hbx_enrollment)}
    let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}

    before(:each) do
      @product = BenefitMarkets::Products::Product.all.where(benefit_market_kind: :aca_individual).first
      @product.update_attributes(ehb: 0.9844)
      premium_table = @product.premium_tables.first
      premium_table.premium_tuples.where(age: 59).first.update_attributes(cost: 614.85)
      premium_table.premium_tuples.where(age: 61).first.update_attributes(cost: 679.8)
      @product.save!
      hbx_enrollment.update_attributes(product: @product)
      hbx_profile.benefit_sponsorship.benefit_coverage_periods.each {|bcp| bcp.update_attributes!(slcsp_id: @product.id)}
      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, hbx_enrollment.effective_on, 59, 'R-DC001').and_return(814.85)
      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, hbx_enrollment.effective_on, 61, 'R-DC001').and_return(879.8)
      person.update_attributes!(dob: (hbx_enrollment.effective_on - 61.years))
      family.family_members[1].person.update_attributes!(dob: (hbx_enrollment.effective_on - 59.years))

      @hbx_enrollment = hbx_enrollment
      @sep = sep
      @family = family
      @self_term_or_cancel_form = ::Insured::Forms::SelfTermOrCancelForm.for_view(
        {
          enrollment_id: hbx_enrollment.id,
          family_id: family.id
        })
      render :template =>"insured/group_selection/edit_plan.html.erb"
    end

    it "should show the ID as hbx_enrollment.hbx_id" do
      expect(rendered).to match(/ID/)
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
