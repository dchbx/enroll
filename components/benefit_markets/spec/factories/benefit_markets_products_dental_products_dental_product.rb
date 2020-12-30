FactoryBot.define do
  factory :benefit_markets_products_dental_products_dental_product, class: 'BenefitMarkets::Products::DentalProducts::DentalProduct' do

    benefit_market_kind  { :aca_shop }
    application_period   { Date.new(Date.today.year, 1, 1)..Date.new(Date.today.year, 12, 31) }
    sequence(:hbx_id)    { |n| n + 98765 }

    sequence(:title)     { |n| "Dental BlueChoice Silver#{n} 2,000" }
    description          { "Highest rated and highest value" }
    premium_ages         { 20..65 }
    dental_level         { 'high' }
    # health_plan_kind     :pos
    ehb                  { 0.9943 }
    network_information  { 'DC Metro' }
    metal_level_kind     { :dental }

    product_package_kinds { [:single_product] }
    sequence(:hios_id, (10..99).cycle)  { |n| "41842DC04000#{n}-01" }
    hios_base_id { hios_id }
    dental_plan_kind { [:ppo, :hmo, :epo].sample }

    service_area { create(:benefit_markets_locations_service_area) }

    # association :service_area, factory: :benefit_markets_locations_service_area, strategy: :create

    trait :with_renewal_product do
      transient do
        renewal_service_area { nil }
        renewal_issuer_profile_id { nil }
      end

      before(:create) do |product, evaluator|
        renewal_product = create(:benefit_markets_products_dental_products_dental_product,
          application_period: (product.application_period.min.next_year..product.application_period.max.next_year),
          product_package_kinds: product.product_package_kinds,
          service_area: evaluator.renewal_service_area,
          metal_level_kind: product.metal_level_kind,
          issuer_profile_id: evaluator.renewal_issuer_profile_id)

        product.renewal_product_id = renewal_product.id
      end
    end

    trait :with_issuer_profile do
      transient do
        assigned_site { nil }
      end

      issuer_profile { create(:benefit_sponsors_organizations_issuer_profile, assigned_site: assigned_site) }
    end

    trait :ivl_product do
      benefit_market_kind  { :aca_individual }
    end

    trait :next_year do
      application_period do
        year = Time.zone.today.next_year.year
        Date.new(year, 1, 1)..Date.new(year, 12, 31)
      end
    end

    after(:build) do |product, evaluator|
      product.premium_tables << build_list(:benefit_markets_products_premium_table, 1, effective_period: product.application_period)
    end

    factory :active_individual_dental_product,       traits: [:ivl_product]
    factory :renewal_individual_dental_product,      traits: [:ivl_product, :next_year]
  end
end
