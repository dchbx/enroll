# frozen_string_literal: true

FactoryBot.define do
  factory :plan_design_census_employee, class: 'SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee' do

    first_name { "Eddie"}
    sequence(:last_name) {|n| "Vedder#{n}" }
    dob { "1964-10-23".to_date }
    gender { "male" }
    expected_selection { "enroll" }
    employee_relationship { "self" }
    hired_on { "2015-04-01".to_date }
    sequence(:ssn) { |n| 222_222_220 + n }
    is_business_owner { false }

    address { build(:sponsored_benefits_locations_address) }
    email { build(:sponsored_benefits_email) }

    # association :sponsored_benefits_locations_address, strategy: :build
    # association :sponsored_benefits_email, strategy: :build
    # association :sponsored_benefits_benefit_sponsorships_plan_design_employer_profile, strategy: :build
    # plan_design_organization            { FactoryBot.build(:plan_design_organization) }

    transient do
      create_with_spouse { false }
    end

    after(:create) do |census_employee, evaluator|
      census_employee.created_at = TimeKeeper.date_of_record
      census_employee.census_dependents.create(employee_relationship: 'spouse') if evaluator.create_with_spouse
    end

    trait :owner do
      is_business_owner { true }
    end

    trait :with_spouse do

    end

    trait :blank_email do
      email { nil }
    end

    trait :with_random_age do
      dob { rand(65.years.ago..18.years.ago) }

      after :create do |census_employee, _evaluator|
        census_employee.census_dependents.create(employee_relationship: 'spouse', dob: rand(census_employee.dob..census_employee.dob + 5.years))
      end
    end
  end
end
