# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe BenefitSponsors::Operations::BenefitApplications::Build, dbclean: :after_each do
  before do
    DatabaseCleaner.clean
  end

  let!(:effective_period_start_on) { TimeKeeper.date_of_record.beginning_of_year }
  let!(:effective_period_end_on)   { TimeKeeper.date_of_record.end_of_year }
  let!(:site) { BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_empty_benefit_market }
  let!(:benefit_market) { site.benefit_markets.first }
  let!(:effective_period) { (effective_period_start_on..effective_period_end_on) }
  let!(:current_benefit_market_catalog) do
    BenefitSponsors::ProductSpecHelpers.construct_benefit_market_catalog_with_renewal_catalog(site, benefit_market, effective_period)
    benefit_market.benefit_market_catalogs.where(
      "application_period.min" => effective_period_start_on
    ).first
  end

  let!(:service_areas) do
    ::BenefitMarkets::Locations::ServiceArea.where(
      :active_year => current_benefit_market_catalog.application_period.min.year
    ).all.to_a
  end

  let!(:rating_area) do
    ::BenefitMarkets::Locations::RatingArea.where(
      :active_year => current_benefit_market_catalog.application_period.min.year
    ).first
  end
  let(:current_effective_date) {TimeKeeper.date_of_record.beginning_of_year}

  include_context 'setup initial benefit application'

  context 'success' do
    let(:current_year) {current_effective_date.year}
    let(:end_of_year) {Date.new(current_year, 12, 31)}

    before do
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 10, 15))
      initial_application.benefit_packages.each do |bp|
        bp.sponsored_benefits.each do |spon_benefit|
          spon_benefit.update_attributes!(_type: 'BenefitSponsors::SponsoredBenefits::HealthSponsoredBenefit')
          create_pd(spon_benefit)
          update_contribution_levels(spon_benefit) if initial_application.employer_profile.is_a_fehb_profile?
        end
      end
    end

    context 'valid benefit application' do
      before do
        reference_product = initial_application.benefit_packages.first.sponsored_benefits.first.reference_product.serializable_hash.deep_symbolize_keys
        application_params = initial_application.serializable_hash.deep_symbolize_keys
        application_params[:benefit_packages].each do |bp_params|
          bp_params[:sponsored_benefits].each do |sb_params|
            sb_params[:reference_product] = reference_product
          end
        end
        @new_ba = subject.call(application_params).success
      end

      it 'should return a success with a BenefitApplication entity' do
        expect(@new_ba).to be_a(BenefitSponsors::Entities::BenefitApplication)
      end

      it 'should return a BenefitApplication with aasm_state active' do
        expect(@new_ba.aasm_state).to eq(:active)
      end

      it 'should return a BenefitApplication with same effective_period' do
        expect(@new_ba.effective_period).to eq(initial_application.effective_period)
      end
    end
  end

  context 'failure' do
    context 'no params' do
      before do
        @result = subject.call({})
      end

      it 'should return a failure with set of missing keys' do
        expect(@result.failure.to_h.keys).to eq([:effective_period, :open_enrollment_period, :aasm_state, :recorded_rating_area_id, :recorded_service_area_ids, :benefit_sponsor_catalog_id])
      end
    end
  end
end

def create_pd(spon_benefit)
  pricing_determination = BenefitSponsors::SponsoredBenefits::PricingDetermination.new({group_size: 4, participation_rate: 75})
  spon_benefit.pricing_determinations << pricing_determination
  pricing_unit_id = spon_benefit.product_package.pricing_model.pricing_units.first.id
  pricing_determination_tier = BenefitSponsors::SponsoredBenefits::PricingDeterminationTier.new({pricing_unit_id: pricing_unit_id, price: 320.00})
  pricing_determination.pricing_determination_tiers << pricing_determination_tier
  spon_benefit.save!
end

def update_contribution_levels(spon_benefit)
  spon_benefit.sponsor_contribution.contribution_levels.each do |cl|
    cl.update_attributes!({contribution_cap: 0.5, flat_contribution_amount: 100.00})
  end
end
