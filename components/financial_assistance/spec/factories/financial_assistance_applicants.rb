# frozen_string_literal: true

FactoryBot.define do
  factory :applicant, class: "::FinancialAssistance::Applicant" do

  end

  factory :financial_assistance_applicant, class: "::FinancialAssistance::Applicant" do
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

    trait :with_ssn do
      sequence(:ssn) { |n| 222222220 + n }
    end

    trait :with_work_email do
      emails { [FactoryBot.build(:email, kind: "work") ] }
    end

    trait :with_work_phone do
      phones { [FactoryBot.build(:phone, kind: "work") ] }
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
