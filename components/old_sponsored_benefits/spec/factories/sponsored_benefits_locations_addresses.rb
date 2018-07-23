FactoryGirl.define do
  factory :sponsored_benefits_locations_address, class: 'SponsoredBenefits::Locations::Address' do

    kind 'home'
    sequence(:address_1, 1111) { |n| "#{n} Awesome Street" }
    sequence(:address_2, 111) { |n| "##{n}" }
    city 'Washington'
    state Settings.aca.state_abbreviation
    zip '01001'
    county 'Hampden'

    trait :work_kind do
      kind 'work'
    end

    trait :mailing_kind do
      kind 'mailing'
    end

    trait :without_kind do
      kind ' '
    end

    trait :without_address_1 do
      address_1 ' '
    end

    trait :without_city do
      city ' '
    end

    trait :without_state do
      state ' '
    end

    trait :without_zip do
      zip ' '
    end

    factory :invalid_address, traits: [:without_kind, :without_address_1,
      :without_city, :without_state, :without_zip]
  end
end