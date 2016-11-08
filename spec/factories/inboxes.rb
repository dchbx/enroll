FactoryGirl.define do
  factory :inbox do
    trait :with_message do
      after(:create) do |i|
        create_list(:message, 2, inbox: i)
      end
    end
  end
end
