FactoryGirl.define do
  factory :quote do
    sequence(:claim_code){|n| Faker::Lorem.characters(8)+ "#{n}"}
    after(:create) do |q, evaluator|
      build(:quote_benefit_group, quote: q )
    end
  end

  trait :with_household_and_members do
    after(:create) do |q, evaluator|
      create(:quote_household,:with_members, quote: q)
    end
  end

  trait :with_two_households_and_members do
    after(:create) do |q, evaluator|
      create_list(:quote_household,2,:with_members, quote: q)
    end
  end

end
