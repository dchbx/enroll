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

    trait :with_one_question_and_accepted_and_declined_responses do
      after(:create) do |qlek, evaluator|
        first_custom_qle_question = qlek.custom_qle_questions.build(
          content: "Please, we need clarification, when did this event occur?"
        )
        first_custom_qle_question.save!
        first_custom_qle_question = qlek.custom_qle_questions.last
        first_qle_question_response_1 = first_custom_qle_question.custom_qle_responses.build(
          content: "Recently",
          action_to_take: 'accepted'
        )
        first_qle_question_response_1.save!
        first_qle_question_response_2 = first_custom_qle_question.custom_qle_responses.build(
          content: "No idea",
          action_to_take: 'declined'
        )
        first_qle_question_response_2.save!
      end
    end

    trait :with_two_questions_accepted_two_question_two_responses_and_accepted_and_declined_responses do
      after(:create) do |qlek, evaluator|
        first_custom_qle_question = qlek.custom_qle_questions.build(
          content: "Please, we need clarification, when did this event occur?"
        )
        first_custom_qle_question.save!
        first_custom_qle_question = qlek.custom_qle_questions.last
        first_qle_question_response_1 = first_custom_qle_question.custom_qle_responses.build(
          content: "Recently",
          action_to_take: 'accepted'
        )
        first_qle_question_response_1.save!
        first_qle_question_response_2 = first_custom_qle_question.custom_qle_responses.build(
          content: "I'll have to think about it.",
          action_to_take: 'two_question_two'
        )
        first_qle_question_response_2.save!
        second_custom_qle_question = qlek.custom_qle_questions.build(
          content: "Let's try this again. When did this event occur?"
        )
        second_custom_qle_question.save!
        second_custom_qle_question = qlek.custom_qle_questions.last
        second_qle_question_response_1 = second_qle_question_response_1.custom_qle_responses.build(
          content: "Recently",
          action_to_take: 'accepted'
        )
        second_qle_question_response_1.save!
        second_qle_question_response_1 = second_qle_question_response_1.custom_qle_responses.build(
          content: "Not sure.",
          action_to_take: 'declined'
        )
      end
    end
  end
end
