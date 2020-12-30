FactoryBot.define do
  factory :benefit_markets_products_product_package, class: 'BenefitMarkets::Products::ProductPackage' do

    application_period do
      start_on  = Date.new(TimeKeeper.date_of_record.year,1,1)
      end_on    = Date.new(TimeKeeper.date_of_record.year,12,31)
      start_on..end_on
    end

    benefit_kind          { :aca_shop }
    product_kind          { :health }
    package_kind          { :single_issuer }

    title                 { "2018 Single Issuer Health Products" }

    contribution_model { create(:benefit_markets_contribution_models_contribution_model) }
    contribution_models { [create(:benefit_markets_contribution_models_contribution_model), create(:benefit_markets_contribution_models_contribution_model, key: :fifty_percent_sponsor_fixed_percent_contribution_model)] }
    pricing_model { create(:benefit_markets_pricing_models_pricing_model) }

    transient do
      number_of_products { 2 }
      county_zip_id { nil }
      service_area { nil }
      issuer_profile { nil }
    end

    after(:build) do |product_package, evaluator|

      county_zip_id = evaluator.county_zip_id || create(:benefit_markets_locations_county_zip, county_name: 'Middlesex', zip: '20024', state: Settings.aca.state_abbreviation).id
      service_area  = evaluator.service_area || create(:benefit_markets_locations_service_area, county_zip_ids: [county_zip_id], active_year: product_package.application_period.min.year)

      case product_package.product_kind
      when :health
        product_package.products = BenefitMarkets::Products::HealthProducts::HealthProduct.by_product_package(product_package).to_a
        if product_package.products.blank?
          product_package.products = create_list(:benefit_markets_products_health_products_health_product,
                                                 evaluator.number_of_products,
                                                 benefit_market_kind: product_package.benefit_kind,
                                                 application_period: product_package.application_period,
                                                 product_package_kinds: [product_package.package_kind],
                                                 service_area: service_area,
                                                 issuer_profile_id: evaluator.issuer_profile.try(:id),
                                                 metal_level_kind: :gold)
        end
      when :dental
        product_package.products = BenefitMarkets::Products::DentalProducts::DentalProduct.by_product_package(product_package).to_a
        if product_package.products.blank?
          product_package.products = create_list(:benefit_markets_products_dental_products_dental_product,
                                                 evaluator.number_of_products,
                                                 benefit_market_kind: product_package.benefit_kind,
                                                 application_period: product_package.application_period,
                                                 product_package_kinds: [product_package.package_kind],
                                                 service_area: service_area,
                                                 issuer_profile_id: evaluator.issuer_profile.try(:id),
                                                 metal_level_kind: :dental)
        end
      end
    end
  end
end
