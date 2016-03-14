FactoryGirl.define do
  factory :general_agency_profile do
    market_kind "both"
    entity_kind "s_corporation"
    association :primary_general_agency_role, factory: :general_agency_role
    organization
    sequence(:corporate_npn) {|n| "2002345#{n}" }
  end
end
