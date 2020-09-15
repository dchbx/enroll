# frozen_string_literal: true

FactoryBot.define do
  factory :applicant, class: "FinancialAssistance::Applicant" do

  end

  factory :financial_assistance_applicant, class: "FinancialAssistance::Applicant" do
    association :application

    is_active true
    is_ia_eligible false
    is_medicaid_chip_eligible false
    is_without_assistance false
    is_totally_ineligible false
    has_fixed_address true
    tax_filer_kind "tax_filer"
    relationship nil
    is_consumer_role true
    is_applying_coverage true
    is_claimed_as_tax_dependent false
    is_self_attested_blind false
    has_daily_living_help false
    need_help_paying_bills false

    trait :with_ssn do
      sequence(:ssn) { |n| 222_222_220 + n }
    end

    trait :with_work_email do
      emails { [FactoryBot.build(:email, kind: "work")] }
    end

    trait :with_work_phone do
      phones { [FactoryBot.build(:phone, kind: "work")] }
    end

    trait :male do
      gender { "male" }
    end

    trait :female do
      gender { "female" }
    end

    trait :child do
      relationship { 'child' }
    end

    trait :spouse do
      relationship { 'spouse' }
    end

    trait :with_home_address do
      addresses { [FactoryBot.build(:financial_assistance_address)]}
    end
  end
end
