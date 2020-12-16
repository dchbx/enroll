# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitMarkets::Operations::BenefitSponsorCatalogs::Clone, dbclean: :after_each do
  before do
    DatabaseCleaner.clean
  end

  let(:effective_date) { Date.new(Date.today.year,6,1) }
  let(:member_relationships) do
    [BenefitMarkets::ContributionModels::MemberRelationship.new(relationship_name: 'employee', relationship_kinds: ['self']),
     BenefitMarkets::ContributionModels::MemberRelationship.new(relationship_name: 'spouse', relationship_kinds: ['spouse']),
     BenefitMarkets::ContributionModels::MemberRelationship.new(relationship_name: 'domestic_partner', relationship_kinds: ['life_partner', 'domestic_partner']),
     BenefitMarkets::ContributionModels::MemberRelationship.new(relationship_name: 'dependent', relationship_kinds: ['child', 'adopted_child', 'foster_child', 'stepchild', 'ward'])]
  end
  let(:contribution_units) do
    [build(:benefit_markets_contribution_models_fixed_percent_contribution_unit,
           :with_member_relationship_maps,
           name: 'employee',
           display_name: 'Employee',
           order: 0,
           default_contribution_factor: 0.0,
           minimum_contribution_factor: 0.0,
           member_relationship_operator: :==),
     build(:benefit_markets_contribution_models_fixed_percent_contribution_unit,
           :with_member_relationship_maps,
           name: 'spouse',
           display_name: 'Spouse',
           order: 1,
           default_contribution_factor: 0.0,
           minimum_contribution_factor: 0.0),
     build(:benefit_markets_contribution_models_fixed_percent_contribution_unit,
           :with_member_relationship_maps,
           name: 'domestic_partner',
           display_name: 'Domestic Partner',
           order: 2,
           default_contribution_factor: 0.0,
           minimum_contribution_factor: 0.0),
     build(:benefit_markets_contribution_models_fixed_percent_contribution_unit,
           :with_member_relationship_maps,
           name: 'dependent',
           display_name: 'Child Under 26',
           order: 3,
           default_contribution_factor: 0.0,
           minimum_contribution_factor: 0.0)]
  end
  let(:contribution_model) do
    cm_params = {sponsor_contribution_kind: '::BenefitSponsors::SponsoredBenefits::FixedPercentSponsorContribution',
                 contribution_calculator_kind: '::BenefitSponsors::ContributionCalculators::SimpleShopReferencePlanContributionCalculator',
                 title: "#{Settings.site.key.to_s.upcase} Shop Simple List Bill Contribution Model",
                 key: :zero_percent_sponsor_fixed_percent_contribution_model,
                 many_simultaneous_contribution_units: true,
                 contribution_units: contribution_units,
                 member_relationships: member_relationships}
    BenefitMarkets::ContributionModels::ContributionModel.new(cm_params)
  end
  let(:product_package) do
    pp = FactoryBot.build(:benefit_markets_products_product_package, contribution_model: contribution_model, assigned_contribution_model: contribution_model, contribution_models: [contribution_model])
    pp.products.each {|product| product.update_attributes!(issuer_profile_id: BSON::ObjectId.new)}
    pp
  end
  let!(:benefit_sponsor_catalog) do
    BenefitMarkets::BenefitSponsorCatalog.new(effective_date: effective_date,
                                              effective_period: effective_date..(effective_date + 1.year - 1.day),
                                              open_enrollment_period: (effective_date - 1.month)..(effective_date - 1.month + 9.days),
                                              probation_period_kinds: [:first_of_month, :first_of_month_after_30_days, :first_of_month_after_60_days],
                                              product_packages: [product_package],
                                              service_areas: [FactoryBot.build(:benefit_markets_locations_service_area)],
                                              sponsor_market_policy: FactoryBot.build(:benefit_markets_market_policies_sponsor_market_policy),
                                              member_market_policy: FactoryBot.build(:benefit_markets_market_policies_member_market_policy))
  end

  context 'success' do
    before do
      @new_bsc = subject.call(benefit_sponsor_catalog: benefit_sponsor_catalog).success
    end

    it 'should return new benefit_sponsor_catalog' do
      expect(@new_bsc).to be_a(::BenefitMarkets::BenefitSponsorCatalog)
    end

    it 'should return a non-persisted benefit_sponsor_catalog' do
      expect(@new_bsc.persisted?).to be_falsy
    end

    it 'should return a benefit_sponsor_catalog with same effective_period' do
      expect(@new_bsc.effective_period).to eq(benefit_sponsor_catalog.effective_period)
    end

    context 'check to verify creation of contribution_units' do
      before do
        @new_cus = @new_bsc.product_packages.first.contribution_model.contribution_units.to_a
      end

      it 'should create contribution_units with proper classes' do
        expect([::BenefitMarkets::ContributionModels::FixedDollarContributionUnit,
                ::BenefitMarkets::ContributionModels::FixedPercentContributionUnit,
                ::BenefitMarkets::ContributionModels::PercentWithCapContributionUnit]).to include(@new_cus.sample.class)
      end
    end

    context 'check to verify creation of pricing_units' do
      before do
        @new_pus = @new_bsc.product_packages.first.pricing_model.pricing_units.to_a
      end

      it 'should create pricing_units with proper classes' do
        expect([::BenefitMarkets::PricingModels::RelationshipPricingUnit,
                ::BenefitMarkets::PricingModels::TieredPricingUnit]).to include(@new_pus.sample.class)
      end
    end

    context 'check to verify creation of products' do
      before do
        @new_products = @new_bsc.product_packages.first.products.to_a
      end

      it 'should create products with proper classes' do
        expect([::BenefitMarkets::Products::HealthProducts::HealthProduct,
                ::BenefitMarkets::Products::DentalProducts::DentalProduct]).to include(@new_products.sample.class)
      end
    end
  end

  context 'failure' do
    context 'no params' do
      before do
        @result = subject.call({})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq('Missing Key.')
      end
    end

    context 'invalid params' do
      before do
        @result = subject.call({benefit_sponsor_catalog: 'benefit_sponsor_catalog'})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq('Not a valid BenefitSponsorCatalog object.')
      end
    end
  end
end
