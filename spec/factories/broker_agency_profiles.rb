FactoryGirl.define do
  factory :broker_agency_profile do
    market_kind "shop"
    entity_kind "s_corporation"
    association :primary_broker_role, factory: :broker_role
    organization
    ach_routing_number '123456789'
    ach_account_number '9999999999999999'
    corporate_npn do
      Forgery('basic').text(:allow_lower   => false,
                            :allow_upper   => false,
                            :allow_numeric => true,
                            :allow_special => false, :exactly => 8)
    end
    # before(:create) do |broker_agency|
    #   FactoryGirl.create(:organization, broker_agency_profile: broker_agency)
    # end
    trait :shop_agency do
      market_kind "shop"
    end
     trait :ivl_agency do
      market_kind "individual"
    end
  end
end
