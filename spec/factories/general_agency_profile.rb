FactoryGirl.define do
  factory :general_agency_profile do
    entity_kind "s_corporation"
    market_kind "shop"
    organization
    sequence(:corporate_npn) {|n| "2002345#{n}" }

    trait :with_staff do
      after :create do |general_agency_profile, evaluator|
        FactoryGirl.create :general_agency_staff_role, general_agency_profile: general_agency_profile
      end
    end
    trait :shop_agency do
      market_kind "shop"
    end
     trait :ivl_agency do
      market_kind "individual"
    end
  end
end
