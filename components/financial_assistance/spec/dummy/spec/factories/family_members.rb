# frozen_string_literal: true

FactoryBot.define do
  factory :family_member do
    association :person
    association :family
    is_primary_applicant { false }
    is_coverage_applicant { true }

    trait :primary do
      is_primary_applicant { true }
    end
  end
end
