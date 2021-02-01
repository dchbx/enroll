# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

# Our helper slug class so we can use the helper methods in our spec
module SpecHelperClassesForViews
  class InsuredFamiliesHelperSlugHostClass
    extend Insured::FamiliesHelper
  end
end

RSpec.describe "insured/group_selection/_enrollment.html.erb", dbclean: :after_each do
  context 'Employer sponsored coverage' do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:person) {FactoryBot.create(:person)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
    let(:employee_role) { FactoryBot.build_stubbed(:employee_role) }
    let(:census_employee) { FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile) }
    let(:benefit_group_assignment) { census_employee.active_benefit_group_assignment }
    let(:active_household) {family.active_household}
    let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family, household: active_household)}
    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :with_issuer_profile) }
    let!(:sep) do
      local_sep = FactoryBot.create(:special_enrollment_period, family: family)
      local_sep.qualifying_life_event_kind.update_attributes!(termination_on_kinds: ['end_of_event_month'])
      local_sep
    end

    before :each do
      allow(hbx_enrollment).to receive(:product).and_return(product)
      allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return false
      allow(hbx_enrollment).to receive(:may_terminate_coverage?).and_return true
      allow(hbx_enrollment).to receive(:is_shop?).and_return true
      allow(hbx_enrollment).to receive(:employer_profile).and_return abc_profile
      allow(hbx_enrollment).to receive(:coverage_year).and_return current_effective_date.year
      allow(hbx_enrollment).to receive(:total_employee_cost).and_return 0
      assign :change_plan, 'change_plan'
      assign :employee_role, employee_role
      assign :person, person
      assign :family, family
      assign :termination_date_options, { hbx_enrollment.id.to_s => ['end_of_event_month']}
      render "insured/group_selection/enrollment", hbx_enrollment: hbx_enrollment
    end

    it "should show Covered" do
      expect(rendered).to match(/Covered/)
    end

    it 'should have title' do
      title = "#{hbx_enrollment.coverage_year} #{product.kind.capitalize} Coverage"
      expect(rendered).to have_content(title)
    end

    it "should have the link of terminate" do
      expect(rendered).to have_selector('a', text: 'Terminate Plan')
    end

    it "should have terminate date" do
      expect(rendered).to have_selector('label', text: 'Termination date: ')
    end

    it "should not have button of change plan" do
      expect(rendered).not_to have_selector('a', text: 'Change Plan')
    end

    it "should show the DCHL ID as hbx_enrollment.hbx_id" do
      expect(rendered).to match /DCHL ID/
      expect(rendered).to match /#{hbx_enrollment.hbx_id}/
    end

    it "should show the correct Premium" do
      dollar_amount = number_to_currency(SpecHelperClassesForViews::InsuredFamiliesHelperSlugHostClass.current_premium(hbx_enrollment), precision: 2)
      expect(rendered).to match /Premium/
      expect(rendered).to include dollar_amount
    end

    it "should have terminate confirmation modal" do
      expect(rendered).to have_selector('h4', text: 'Select Terminate Reason')
    end

    it 'should have css terminated_on' do
      expect(rendered).to have_css("select[name='terminated_on']")
      expect(rendered).to have_selector("[name='terminated_on']")
    end
  end

  if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
    context 'Enrollment termination' do
      let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
      let(:hbx_enrollment) { FactoryBot.build(:hbx_enrollment, :with_enrollment_members, family: family, household: family.active_household, kind: kind)}
      let(:person) { FactoryBot.build(:person) }
      let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :with_issuer_profile) }

      before :each do
        allow(hbx_enrollment).to receive(:product).and_return(product)
        allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return false
        allow(hbx_enrollment).to receive(:may_terminate_coverage?).and_return true
        allow(hbx_enrollment).to receive(:is_shop?).and_return false
        assign :change_plan, 'change_plan'
        assign :person, person
        assign :family, family
        render "insured/group_selection/enrollment", hbx_enrollment: hbx_enrollment
      end

      context 'with Individual coverage' do
        let(:kind) { 'individual' }

        it "should not have terminate confirmation modal" do
          expect(rendered).not_to have_selector('h4', text: 'Select Terminate Reason')
        end
      end

      context 'with Coverall coverage' do
        let(:kind) { 'coverall' }

        it "should not have terminate confirmation modal" do
          expect(rendered).not_to have_selector('h4', text: 'Select Terminate Reason')
        end
      end
    end
  end
end
