# frozen_string_literal: true

FactoryBot.define do
  factory :broker_role do
    person { FactoryBot.create(:person, :with_work_phone, :with_work_email) }
    npn do
      Forgery('basic').text(:allow_lower => false,
                            :allow_upper => false,
                            :allow_numeric => true,
                            :allow_special => false, :exactly => 8)
    end

    provider_kind {"broker"}

    trait :with_invalid_provider_kind do
      provider_kind { ' ' }
    end
  end
end
