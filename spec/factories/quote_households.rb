FactoryGirl.define do
  factory :quote_household do
  	sequence(:family_id){|n|"#{n}"}
  end

  trait :with_members do
		after(:create) do |qh, evaluator|
      create_list(:quote_member,1, quote_household: qh)
    end
  end
end