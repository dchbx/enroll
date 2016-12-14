FactoryGirl.define do
  factory :quote_household do
    sequence(:family_id){|n|"#{n}"}
    quote_benefit_group_id {@qbg_id_testing}
  end

  trait :with_members do
    after(:create) do |qh, evaluator|
      create_list(:quote_member,1, quote_household: qh)
    end
  end

  trait :with_quote_family do
    after(:create) do |qh, evalulator|
      create(:quote_member, quote_household: qh)
      create(:quote_spouse, quote_household: qh)
    end
  end
end