namespace :qle do
  desc "add new qles for coverall to ivl or ivl to coverall transition members"
  task add_new_ivl_qles: :environment do

    QualifyingLifeEventKind.create!(
        title: "Not eligible for marketplace coverage due to citizenship or immigration status",
        tool_tip: " ",
        action_kind: "transition_member",
        market_kind: "individual",
        ordinal_position: 120,
        reason: "eligibility_failed_or_documents_not_received_by_due_date",
        edi_code: " ",
        effective_on_kinds: ["first_of_next_month", "first_of_month"],
        pre_event_sep_in_days: 0,
        post_event_sep_in_days: 60,
        is_self_attested: false,
        date_options_available: false,
        # coverage_effective_date: "Regular effective date")
    )

    QualifyingLifeEventKind.create!(
        title: "Provided documents proving eligibility",
        tool_tip: " ",
        action_kind: "transition_member",
        market_kind: "individual",
        ordinal_position: 120,
        reason: "eligibility_documents_provided",
        edi_code: " ",
        effective_on_kinds: ["first_of_next_month", "first_of_month"],
        pre_event_sep_in_days: 0,
        post_event_sep_in_days: 60,
        is_self_attested: false,
        date_options_available: false,
        # start_of_sep: "Date approved by HBX",
        # coverage_effective_date: "Regular effective date")
    )
  end
end