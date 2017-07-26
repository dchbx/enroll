FactoryGirl.define do
  factory :phone do
    kind 'home'
    # sequence(:area_code, WrappingSequence.new(100, 999)) { |n| "#{n}"}
    area_code 202
    sequence(:number, 1111111) { |n| "#{n}"}
    sequence(:extension) { |n| "#{n}"}


    trait :for_testing do
      kind 'home'
      area_code "101"
      number "1234567"
      extension "111"
      country_code "1"
    end
    trait :without_kind do
      kind ' '
    end

    trait :without_area_code do
      area_code ' '
    end

    trait :without_number do
      number ' '
    end

    factory :invalid_phone, traits: [:without_kind, :without_area_code, :without_number]

  end
end
