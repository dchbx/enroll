FactoryGirl.define do
  factory :benefit_markets_benefit_market, class: 'BenefitMarkets::BenefitMarket' do
    site_urn 'acme'
    site  { build(:benefit_sponsors_site) }
    kind :aca_shop
    title "DC Health Link SHOP Market"
    description "Health Insurance Marketplace for District Employers and Employees"

    after :build do |benefit_market|
      if benefit_market.kind == :aca_shop
        benefit_market.configuration = build :benefit_markets_aca_shop_configuration
      else
        benefit_market.configuration = build :benefit_markets_aca_individual_configuration
      end
    end

    trait :with_site do
      after :build do |benefit_market, evaluator|
        build(:benefit_sponsors_site, :with_owner_exempt_organization, benefit_markets: [benefit_market])
      end
    end

    trait :with_benefit_catalog do
      after :build do |benefit_market, evaluator|
        benefit_market.add_benefit_market_catalog(build(:benefit_markets_benefit_catalog))
      end
    end

    trait :with_benefit_catalog_and_product_packages do

      after :build do |benefit_market, evaluator|
        benefit_market.add_benefit_market_catalog(build(:benefit_markets_benefit_catalog, :with_product_packages))
      end
    end

  end
end
