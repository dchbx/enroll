FactoryGirl.define do
  factory :benefit_markets_benefit_sponsor_catalog, class: 'BenefitMarkets::BenefitSponsorCatalog' do

    effective_date          {
                                this_year = Date.today.year
                                Date.new(this_year,6,1)
                              }
    effective_period        { effective_date..(effective_date + 1.year - 1.day) }
    open_enrollment_period  { (effective_date - 1.month)..(effective_date - 1.month + 9.days) }
    probation_period_kinds  { [:first_of_month, :first_of_month_after_30_days, :first_of_month_after_60_days] }
    service_areas           { [FactoryGirl.build(:benefit_markets_locations_service_area)] }
    sponsor_market_policy   { FactoryGirl.build(:benefit_markets_market_policies_sponsor_market_policy) }
    member_market_policy    { FactoryGirl.build(:benefit_markets_market_policies_member_market_policy) }
    product_packages        { [FactoryGirl.build(:benefit_markets_products_product_package)] }

    # let(:sponsor_market_policy)   { BenefitMarkets::MarketPolicies::SponsorMarketPolicy.new }
    # let(:member_market_policy)    { BenefitMarkets::MarketPolicies::MemberMarketPolicy.new }
    # let(:product_packages)        { [FactoryGirl.build(:benefit_markets_products_product_package)] }

  end
end
