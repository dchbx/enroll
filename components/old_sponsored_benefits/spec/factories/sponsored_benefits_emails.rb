FactoryGirl.define do
  factory :sponsored_benefits_email, class: 'SponsoredBenefits::Email' do
    kind 'home'
    sequence(:address) { |n| "example#{n}@example.com" }

    trait :without_email_type do
      kind ' '
    end

    trait :without_email_address do
      kind ' '
    end

    factory :invalid_email, traits: [:without_email_type, :without_email_address]
  end
end