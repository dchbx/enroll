FactoryBot.define do
  factory :benefit_markets_products_health_products_health_product, class: 'BenefitMarkets::Products::HealthProducts::HealthProduct' do

    benefit_market_kind  { :aca_shop }
    application_period   { Date.new(Date.today.year, 1, 1)..Date.new(Date.today.year, 12, 31) }
    sequence(:hbx_id)    { |n| n + 12345 }

    sequence(:title)     { |n| "#{issuer_name} #{metal_level_kind}#{n} 2,000" }
    description          { "Highest rated and highest value" }
    health_plan_kind     { :pos }
    ehb                  { 0.9943 }
    metal_level_kind     { BenefitMarkets::Products::HealthProducts::HealthProduct::METAL_LEVEL_KINDS.sample }
    dc_in_network        { true }
    nationwide           { true }
    deductible           { "$500 per person" }
    family_deductible    { "$500 per person | $1000 per group" }

    product_package_kinds { [:single_product, :single_issuer, :metal_level] }
    sequence(:hios_id, (10..99).cycle)  { |n| "41842DC04000#{n}-01" }
    hios_base_id          { hios_id.split('-')[0] }

    service_area { create(:benefit_markets_locations_service_area) }

    transient do
      issuer_name { 'BlueChoice' }
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

    trait :csr_87 do
      metal_level_kind        { :silver }
      benefit_market_kind     { :aca_individual }
      csr_variant_id          { "87" }
    end

    trait :csr_00 do
      metal_level_kind        { :silver }
      benefit_market_kind     { :aca_individual }
      csr_variant_id          { "00" }
    end

    trait :catastrophic do
      metal_level_kind        { :catastrophic }
      benefit_market_kind     { :aca_individual }
    end

    trait :gold do
      metal_level_kind        { :gold }
      benefit_market_kind     { :aca_individual }
    end

    trait :silver do
      metal_level_kind        { :silver }
      benefit_market_kind     { :aca_individual }
    end

    trait :with_issuer_profile do
      transient do
        assigned_site { nil }
      end

      issuer_profile { create(:benefit_sponsors_organizations_issuer_profile, assigned_site: assigned_site) }
    end

    trait :with_renewal_product do
      transient do
        renewal_service_area { nil }
        renewal_issuer_profile_id { nil }
      end

      before(:create) do |product, evaluator|
        renewal_product = create(:benefit_markets_products_health_products_health_product,
          application_period: (product.application_period.min.next_year..product.application_period.max.next_year),
          product_package_kinds: product.product_package_kinds,
          service_area: evaluator.renewal_service_area,
          metal_level_kind: product.metal_level_kind,
          issuer_profile_id: evaluator.renewal_issuer_profile_id)

        product.renewal_product_id = renewal_product.id
      end
    end

    # association :service_area, factory: :benefit_markets_locations_service_area, strategy: :create

    after(:build) do |product, evaluator|
      product.premium_tables << build_list(:benefit_markets_products_premium_table, 1, effective_period: product.application_period, rating_area: FactoryBot.create(:benefit_markets_locations_rating_area))
    end

    factory :active_individual_health_product,       traits: [:ivl_product]
    factory :renewal_individual_health_product,      traits: [:ivl_product, :next_year]

    factory :active_individual_catastophic_product,  traits: [:catastrophic]
    factory :renewal_individual_catastophic_product, traits: [:catastrophic, :next_year]

    factory :active_csr_87_product,                  traits: [:csr_87]
    factory :active_csr_00_product,                  traits: [:csr_00]

    factory :renewal_csr_87_product,                 traits: [:csr_87, :next_year]
    factory :renewal_csr_00_product,                 traits: [:csr_00, :next_year]

    factory :active_ivl_gold_health_product,         traits: [:gold]
    factory :renewal_ivl_gold_health_product,        traits: [:gold, :next_year]

    factory :active_ivl_silver_health_product,      traits: [:silver, :next_year]
    factory :renewal_ivl_silver_health_product,      traits: [:silver, :next_year]

  end
end
