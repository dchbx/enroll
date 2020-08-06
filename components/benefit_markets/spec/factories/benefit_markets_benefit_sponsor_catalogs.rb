# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_markets_benefit_sponsor_catalog, class: 'BenefitMarkets::BenefitSponsorCatalog' do

    effective_date          do
      this_year = Date.today.year
      Date.new(this_year,6,1)
    end
    effective_period        { effective_date..(effective_date + 1.year - 1.day) }
    open_enrollment_period  { (effective_date - 1.month)..(effective_date - 1.month + 9.days) }
    probation_period_kinds  { [:first_of_month, :first_of_month_after_30_days, :first_of_month_after_60_days] }
    service_areas           { [FactoryBot.build(:benefit_markets_locations_service_area)] }
    sponsor_market_policy   { FactoryBot.build(:benefit_markets_market_policies_sponsor_market_policy) }
    member_market_policy    { FactoryBot.build(:benefit_markets_market_policies_member_market_policy) }
    # product_packages        { [FactoryBot.build(:benefit_markets_products_product_package)] }

    after(:build) do |benefit_sponsor_catalog, _evaluator|
      benefit_sponsor_catalog.product_packages = [
        FactoryBot.build(:benefit_markets_products_product_package),
        FactoryBot.build(:benefit_markets_products_product_package, product_kind: :dental, package_kind: :single_product)
      ]
    end

    # let(:sponsor_market_policy)   { BenefitMarkets::MarketPolicies::SponsorMarketPolicy.new }
    # let(:member_market_policy)    { BenefitMarkets::MarketPolicies::MemberMarketPolicy.new }
    # let(:product_packages)        { [FactoryBot.build(:benefit_markets_products_product_package)] }

  end
end
