FactoryGirl.define do
  factory :individual_market_transition do
    association :person

    role_type 'consumer'
    reason_code 'generating_consumer_role'


    trait :resident do
      role_type 'resident'
      reason_code 'generating_resident_role'
    end
  end
end