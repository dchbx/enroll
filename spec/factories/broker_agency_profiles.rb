FactoryGirl.define do
  factory :broker_agency_profile do
    market_kind "both"
    entity_kind "s_corporation"
    association :primary_broker_role, factory: :broker_role
    organization
    corporate_npn do
      Forgery('basic').text(:allow_lower   => false,
                            :allow_upper   => false,
                            :allow_numeric => true,
                            :allow_special => false, :exactly => 8)
    end
    # before(:create) do |broker_agency|
    #   FactoryGirl.create(:organization, broker_agency_profile: broker_agency)
    # end
    trait :with_aasm_state_approved do 
        aasm_state "is_approved"
    end
  end
end

