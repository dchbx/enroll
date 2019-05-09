FactoryBot.define do
  factory :benefit_markets_benefit_market_catalog, class: 'BenefitMarkets::BenefitMarketCatalog' do

    title                     { "Benefit Buddy's SHOP Employer Benefit Market" }
    description               { "Some awesome description text here" }
    application_interval_kind { :monthly }
    application_period        { Date.new(Date.today.year, 1, 1)..Date.new(Date.today.year, 12, 31) }
    probation_period_kinds    { [:first_of_month, :first_of_month_after_30_days, :first_of_month_after_60_days] }
    sponsor_market_policy     { build(:benefit_markets_market_policies_sponsor_market_policy) }
    member_market_policy      { build(:benefit_markets_market_policies_member_market_policy) }

    transient do
      health_product_package_kinds { [:single_product, :single_issuer, :metal_level] }
      dental_product_package_kinds { [:single_product] }
      number_of_products { 5 }
      product_kinds { [:health, :dental] }
      service_area { nil }
      issuer_profile { nil }
    end

    association :benefit_market, factory: :benefit_markets_benefit_market

    trait :with_product_packages do

      after(:build) do |benefit_market_catalog, evaluator|
        def create_product_package(product_kind, package_kind, benefit_market_catalog, evaluator)
          build(:benefit_markets_products_product_package, 
            packagable: benefit_market_catalog, 
            package_kind: package_kind, 
            product_kind: product_kind,
            title: "#{package_kind.to_s.humanize} #{product_kind}",
            description: "#{package_kind.to_s.humanize} #{product_kind}",
            application_period: benefit_market_catalog.application_period,
            number_of_products: evaluator.number_of_products,
            service_area: evaluator.service_area,
            issuer_profile: evaluator.issuer_profile
          )
        end

        evaluator.product_kinds.each do |product_kind|
          case product_kind
          when :health
            evaluator.health_product_package_kinds.each do |package_kind|
              benefit_market_catalog.product_packages << create_product_package(product_kind, package_kind, benefit_market_catalog, evaluator)
            end
          when :dental
            evaluator.dental_product_package_kinds.each do |package_kind|
              benefit_market_catalog.product_packages << create_product_package(product_kind, package_kind, benefit_market_catalog, evaluator)
            end
          end
        end
      end
    end
  end
end
