# For Ex: RAILS_ENV=production bundle exec rake qle_kind_wizard_test_seed:seed_qle_kind_data
# This is to provide QLE Kinds ready to edit, deactivate, and display as SEP for testing
namespace :qle_kind_wizard_test_seed do
  desc "Upload invoice to and associate with employer"
  task :seed_qle_kind_data => :environment do
    # For Editing
    editable_qle_kind = QualifyingLifeEventKind.find_or_create_by(
      title: "Yet another new birth",
      tool_tip: "Household adds a new family member due to marriage, birth, adoption, placement for adoption, or placement in foster care",
      action_kind: "add_benefit",
      is_active: false,
      reason: "birth",
      edi_code: "99-YET-ANOTHER-NEW-BIRTH", 
      market_kind: "shop", 
      effective_on_kinds: ["date_of_event"],
      pre_event_sep_in_days: 0,
      post_event_sep_in_days: 30, 
      is_self_attested: true, 
      date_options_available: false,
      ordinal_position: 25,
      visible_to_customer: true,

    )
    puts("Editable QLE Kind present.") if editable_qle_kind.present?
    # For Deactivation
    deactivatable_qle_kind = QualifyingLifeEventKind.find_or_create_by!(
      title: "Federal Government order to provide coverage for someone",
      end_on: nil,
      is_active: true,
      tool_tip: "",
      action_kind: "add_member",
      market_kind: "shop",
      event_kind_label: "Date that feds order that coverage starts",
      ordinal_position: 100,
      reason: "court_order",
      edi_code: " ",
      effective_on_kinds: ["exact_date"],
      pre_event_sep_in_days: 0,
      post_event_sep_in_days: 60,
      is_self_attested: false,
      visible_to_customer: true,
      date_options_available: false,
    )
    puts("Deactivatable QLE Kind present.") if deactivatable_qle_kind.present?
    # For display on the families home page/wherever SEP is showed
    individual_self_attested_qle_kind = QualifyingLifeEventKind.find_or_create_by!(
      title: "Federal Government order to provide coverage for someone",
      tool_tip: "",
      is_active: false,
      action_kind: "add_member",
      market_kind: "individual",
      event_kind_label: "Date that court orders that coverage starts",
      ordinal_position: 100,
      reason: "court_order",
      edi_code: " ",
      effective_on_kinds: ["exact_date"],
      pre_event_sep_in_days: 0,
      post_event_sep_in_days: 60,
      is_self_attested: true,
      visible_to_customer: true,
      date_options_available: false,
    )
    # First question
    first_custom_qle_question = individual_self_attested_qle_kind.custom_qle_questions.build(
      content: "Please, we need clarification, who is the person you're getting coverage for?"
    )
    first_custom_qle_question.save!
    first_custom_qle_question = individual_self_attested_qle_kind.custom_qle_questions.last
    # First question first response
    first_qle_question_response_1 = first_custom_qle_question.custom_qle_responses.build(
      content: "I don't know",
      action_to_take: 'to_question_2'
    )
    first_qle_question_response_1.save!
    # first question second response
    first_qle_question_response_2 = first_custom_qle_question.custom_qle_responses.build(
      content: "It's a family member",
      action_to_take: 'accepted'
    )
    first_qle_question_response_2.save!
    # Second Question
    second_custom_qle_question = individual_self_attested_qle_kind.custom_qle_questions.build(
      content: "Ok, let's try this again, who is the person you're getting coverage for?"
    )
    second_custom_qle_question.save!
    second_custom_qle_question = individual_self_attested_qle_kind.custom_qle_questions.last
    # Second Question Response 1
    second_custom_qle_question_response_1 = first_custom_qle_question.custom_qle_responses.build(
      content: "It's a family member",
      action_to_take: 'accepted'
    )
    # Second Question Response 2
    second_custom_qle_question_response_2 = first_custom_qle_question.custom_qle_responses.build(
      content: "I don't know",
      action_to_take: 'declined'
    )
    puts("Individual self attested QLE Kind present.") if individual_self_attested_qle_kind.present?
    # For QLE Kind with two custom QLE questions
    qle_kind_with_two_questions = QualifyingLifeEventKind.find_or_create_by!(
      title: "Local government order to provide coverage for someone",
      end_on: nil,
      tool_tip: "",
      action_kind: "add_member",
      market_kind: "shop",
      event_kind_label: "Date that local gov orders that coverage starts",
      ordinal_position: 100,
      reason: "court_order",
      edi_code: " ",
      effective_on_kinds: ["exact_date"],
      pre_event_sep_in_days: 0,
      post_event_sep_in_days: 60,
      is_self_attested: false,
      date_options_available: false,
    )
    # First question
    first_custom_qle_question = qle_kind_with_two_questions.custom_qle_questions.build(
      content: "Please, we need clarification, who is the person you're getting coverage for?"
    )
    first_custom_qle_question.save!
    first_custom_qle_question = qle_kind_with_two_questions.custom_qle_questions.last
    # First question first response
    first_qle_question_response_1 = first_custom_qle_question.custom_qle_responses.build(
      content: "I don't know",
      action_to_take: 'to_question_2'
    )
    first_qle_question_response_1.save!
    # first question second response
    first_qle_question_response_2 = first_custom_qle_question.custom_qle_responses.build(
      content: "It's a family member",
      action_to_take: 'accepted'
    )
    first_qle_question_response_2.save!
    # Second Question
    second_custom_qle_question = qle_kind_with_two_questions.custom_qle_questions.build(
      content: "Ok, let's try this again, who is the person you're getting coverage for?"
    )
    second_custom_qle_question.save!
    second_custom_qle_question = qle_kind_with_two_questions.custom_qle_questions.last
    # Second Question Response 1
    second_custom_qle_question_response_1 = second_custom_qle_question.custom_qle_responses.build(
      content: "It's a family member",
      action_to_take: 'accepted'
    )
    # Second Question Response 2
    second_custom_qle_question_response_2 = second_custom_qle_question.custom_qle_responses.build(
      content: "I don't know",
      action_to_take: 'declined'
    )
    puts("Qle Kind with multiple questions present.") if qle_kind_with_two_questions.custom_qle_questions.present?
    # Custom QLE Kind with One Question
    qle_kind_with_one_question = QualifyingLifeEventKind.find_or_create_by!(
      title: "UN Mandate to provide coverage for someone",
      end_on: nil,
      tool_tip: "",
      action_kind: "add_member",
      market_kind: "individual",
      event_kind_label: "Date that UN gov orders that coverage starts",
      ordinal_position: 100,
      reason: "court_order",
      edi_code: " ",
      effective_on_kinds: ["exact_date"],
      pre_event_sep_in_days: 0,
      post_event_sep_in_days: 60,
      is_self_attested: false,
      date_options_available: false,
      visible_to_customer: true
    )
    # First question
    first_custom_qle_question = qle_kind_with_one_question.custom_qle_questions.build(
      content: "Please, we need clarification, who is the person you're getting coverage for?"
    )
    first_custom_qle_question.save!
    first_custom_qle_question = qle_kind_with_one_question.custom_qle_questions.last
    # First question first response
    first_qle_question_response_1 = first_custom_qle_question.custom_qle_responses.build(
      content: "I don't know",
      action_to_take: 'declined'
    )
    first_qle_question_response_1.save!
    # first question second response
    first_qle_question_response_2 = first_custom_qle_question.custom_qle_responses.build(
      content: "It's a family member",
      action_to_take: 'accepted'
    )
    first_qle_question_response_2.save!
    first_qle_question_response_3 = first_custom_qle_question.custom_qle_responses.build(
      content: "Not a lcue.",
      action_to_take: 'declined'
    )
    first_qle_question_response_3.save!
    puts("Qle Kind with one question present.") if qle_kind_with_one_question.custom_qle_questions.present?
  end
end
