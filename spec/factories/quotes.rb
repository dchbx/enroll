FactoryGirl.define do
  factory :quote do
    start_on "2017-07-02"
    claim_code nil
    after(:create) do |q, evaluator|
      create(:quote_benefit_group, quote: q )
      @qbg_id_testing = q.quote_benefit_groups.last.id
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

  trait :with_two_families do
    after(:create) do |q, evaluator|
      create_list(:quote_household,2,:with_quote_family, quote: q)
    end
  end

end
