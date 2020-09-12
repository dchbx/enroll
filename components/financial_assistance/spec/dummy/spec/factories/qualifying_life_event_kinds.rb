# frozen_string_literal: true

FactoryBot.define do
  factory :qualifying_life_event_kind do

    title { "Married" }
    action_kind { "add" }
    edi_code { "32-MARRIAGE" }
    reason { "marriage" }
    market_kind { "shop" }
    effective_on_kinds { ["first_of_month"] }
    pre_event_sep_in_days { 0 }
    post_event_sep_in_days { 30 }
    is_self_attested { true }
    ordinal_position { 15 }
    tool_tip { "Enroll or add a family member because of marriage" }

    trait :effective_on_event_date do
      title { "Had a baby" }
      edi_code { "02-BIRTH" }
      effective_on_kinds { ["date_of_event"] }
      tool_tip { "Enroll or add a family member due to birth" }
    end

    trait :effective_on_first_of_month do
      title { "Married" }
      edi_code { "32-MARRIAGE" }
      reason { "marriage" }
      effective_on_kinds { ["first_of_next_month"] }
      tool_tip { "Enroll or add a family member because of marriage" }
    end

    trait :effective_on_event_date_and_first_month do
      title { "Had a baby" }
      edi_code { "02-BIRTH" }
      effective_on_kinds { ["date_of_event", "first_of_next_month"] }
      tool_tip { "Enroll or add a family member due to birth" }
    end
  end
end
