# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Operations::Products::Load, dbclean: :after_each do

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
  let!(:issuer_profile) { double(id: BSON::ObjectId.new) }

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
  let(:params) do
    {
      application_period: application_period,
      benefit_kind: benefit_kind,
      package_kind: package_kind,
      product_kind: product_kind
    }
  end

  context 'when passed health product kind' do

    it 'should return health products' do
      result = subject.call(params)
      expect(result.success?).to be_truthy
      products = subject.call(params).success
      expect(products.count).to eq 5
      expect(products.map(&:kind).uniq).to eq [product_kind]
      expect(products.map(&:application_period).uniq).to eq [application_period]
      expect(products.first).to be_a BenefitMarkets::Entities::HealthProduct
    end
  end

  context 'when passed dental product kind' do
    let(:product_kind) { :dental }
    let(:package_kind) { :single_product }

    it 'should return dental products' do
      result = subject.call(params)
      expect(result.success?).to be_truthy
      products = subject.call(params).success
      expect(products.count).to eq 5
      expect(products.map(&:kind).uniq).to eq [product_kind]
      expect(products.map(&:application_period).uniq).to eq [application_period]
      expect(products.first).to be_a BenefitMarkets::Entities::DentalProduct
    end
  end
end

