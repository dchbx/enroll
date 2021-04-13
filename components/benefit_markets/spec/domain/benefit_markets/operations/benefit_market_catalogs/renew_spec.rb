# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Operations::BenefitMarketCatalogs::Renew, dbclean: :after_each do

  let(:catalog_health_package_kinds) { [:single_issuer, :metal_level, :single_product] }
  let(:catalog_dental_package_kinds) { [:single_product] }

  let!(:service_area) do
    county_zip_id = create(:benefit_markets_locations_county_zip, county_name: 'Middlesex', zip: '20024', state: Settings.aca.state_abbreviation).id
    create(:benefit_markets_locations_service_area, county_zip_ids: [county_zip_id], active_year: effective_date.year - 1)
  end

  let!(:renewal_service_area) do
    create(:benefit_markets_locations_service_area, county_zip_ids: service_area.county_zip_ids, active_year: effective_date.year)
  end

  let(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let(:issuer_profile) { double(id: BSON::ObjectId.new) }
  let(:product_kinds) { [:health] }
  let(:benefit_market) { site.benefit_markets.first }

  let!(:health_products) do
    create_list(:benefit_markets_products_health_products_health_product,
                5,
                :with_renewal_product,
                application_period: (application_period.min.prev_year..application_period.max.prev_year),
                product_package_kinds: catalog_health_package_kinds,
                service_area: service_area,
                renewal_service_area: renewal_service_area,
                issuer_profile_id: issuer_profile.id,
                renewal_issuer_profile_id: issuer_profile.id,
                metal_level_kind: :gold)
  end

  let!(:dental_products) do
    create_list(:benefit_markets_products_dental_products_dental_product,
                5,
                :with_renewal_product,
                application_period: (application_period.min.prev_year..application_period.max.prev_year),
                product_package_kinds: catalog_dental_package_kinds,
                service_area: service_area,
                renewal_service_area: renewal_service_area,
                issuer_profile_id: issuer_profile.id,
                renewal_issuer_profile_id: issuer_profile.id,
                metal_level_kind: :dental)
  end

  let(:effective_date) { TimeKeeper.date_of_record.end_of_year + 1.day }
  let(:application_period) { effective_date..(effective_date + 1.year).prev_day }
  let(:benefit_kind) { :aca_shop }
  let(:package_kind) { :single_issuer }
  let(:product_kind) { :health }

  let(:existing_product_package) { current_benefit_market_catalog.product_packages.first }

  let!(:current_benefit_market_catalog) do
    create(:benefit_markets_benefit_market_catalog, :with_product_packages,
           benefit_market: benefit_market,
           product_kinds: product_kinds,
           title: "SHOP Benefits for #{application_period.min.prev_year.year}",
           health_product_package_kinds: catalog_health_package_kinds,
           dental_product_package_kinds: catalog_dental_package_kinds,
           application_period: (application_period.min.prev_year..application_period.max.prev_year))
  end

  let(:params) { {market_kind: :aca_shop, effective_date: effective_date.prev_year} }

  context 'sending required parameters' do
    it 'should create benefit market catalog' do
      result = subject.call(params)
      expect(result.success?).to be_truthy
      catalog = result.success

      expect(catalog.product_packages.count).to eq current_benefit_market_catalog.product_packages.count
    end
  end
end
