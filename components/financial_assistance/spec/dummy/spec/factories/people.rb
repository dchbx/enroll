# frozen_string_literal: true

FactoryBot.define do
  factory :person do
    # name_pfx 'Mr'
    first_name { 'John' }
    # middle_name 'X'
    sequence(:last_name) {|n| "Smith#{n}" }
    # name_sfx 'Jr'
    dob { "1972-04-04".to_date }
    is_incarcerated { false }
    is_active { true }
    gender { "male" }

    trait :with_broker_role do
      after(:create) do |p, _evaluator|
        create_list(:broker_role, 1, person: p)
      end
    end

    trait :with_ssn do
      sequence(:ssn) { |n| 222_222_220 + n }
    end

    trait :with_general_agency_staff_role do
      after(:create) do |p, _evaluator|
        create_list(:general_agency_staff_role, 1, person: p)
      end
    end

    trait :with_family do
      after :create do |person|
        FactoryBot.create :family, :with_primary_family_member, person: person
      end
    end

    trait :male do
      gender { "male" }
    end

    trait :female do
      gender { "female" }
    end

    trait :with_work_phone do
      phones { [FactoryBot.build(:phone, kind: "work")] }
    end

    trait :with_work_email do
      emails { [FactoryBot.build(:email, kind: "work")] }
    end

    trait :with_employee_role do
      after(:create) do |p, _evaluator|
        create_list(:benefit_sponsors_employee_role, 1, person: p)
      end
    end

    trait :with_consumer_role do
      after(:create) do |p, _evaluator|
        create_list(:consumer_role, 1, person: p, dob: p.dob)
      end
    end

    trait :with_active_consumer_role do
      after(:create) do |person|
        FactoryBot.create :individual_market_transition, person: person
      end
    end
  end
end
