FactoryGirl.define do
  factory :qualifying_life_event_kind do

    title "Married"
    action_kind "add"
    edi_code "32-MARRIAGE"
    reason "marriage"
    market_kind "shop"
    effective_on_kinds ["first_of_month"]
    pre_event_sep_in_days 0
    post_event_sep_in_days 30
    is_self_attested true
    ordinal_position 15
    tool_tip "Enroll or add a family member because of marriage"

    trait :effective_on_event_date do
      title "Had a baby"
      edi_code "02-BIRTH"
      effective_on_kinds ["date_of_event"]
      tool_tip "Enroll or add a family member due to birth"
    end

    trait :effective_on_first_of_month do
      title "Married"
      edi_code "32-MARRIAGE"
      reason "marriage"
      effective_on_kinds ["first_of_next_month"]
      tool_tip "Enroll or add a family member because of marriage"
    end
    
    trait :death_of_dependent do
      title "A family member has died"
      edi_code "03-DEATH"
      reason "death"
      effective_on_kinds ["first_of_next_month"]
      tool_tip "Remove a family member due to death"
    end
  end
end
