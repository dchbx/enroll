puts "*"*80
puts "::: Cleaning QualifyingLifeEventKinds :::"
QualifyingLifeEventKind.delete_all

QualifyingLifeEventKind.create!(
    title: "Had a baby",
    tool_tip: "Household adds a member due to marriage, birth, adoption, placement for adoption, or placement in foster care",
    action_kind: "add_benefit",
    reason: "birth",
    edi_code: "02-BIRTH", 
    market_kind: "shop", 
    effective_on_kinds: ["date_of_event"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    date_options_available: false,
    ordinal_position: 25,
    event_kind_label: 'Date of birth'
  )

QualifyingLifeEventKind.create!(
    title: "Adopted a child",
    action_kind: "add_benefit",
    reason: "adoption",
    edi_code: "05-ADOPTION", 
    market_kind: "shop", 
    effective_on_kinds: ["date_of_event"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    date_options_available: false,
    ordinal_position: 30,
    event_kind_label: "Date of adoption",
    tool_tip: "Enroll or add a family member due to adoption"
  )

QualifyingLifeEventKind.create!(
    title: "Married",
    action_kind: "add_benefit",
    reason: "marriage",
    edi_code: "32-MARRIAGE", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    date_options_available: false,
    ordinal_position: 15,
    event_kind_label: 'Date of married',
    tool_tip: "Enroll or add a family member because of marriage"
  )

QualifyingLifeEventKind.create!(
    title: "Entered into a legal domestic partnership",
    tool_tip: "Entering a domestic partnership as permitted or recognized by the District of Columbia",
    action_kind: "add_benefit",
    reason: "domestic_partnership",
    edi_code: "33-ENTERING DOMESTIC PARTNERSHIP", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    date_options_available: false,
    ordinal_position: 20,
    event_kind_label: 'Date of domestic partnership'
  )

QualifyingLifeEventKind.create!(
    title: "Divorced", 
    tool_tip: "Divorced, ended a domestic partnership, or legally separated",
    action_kind: "drop_member",
    reason: "divorce",
    edi_code: "01-DIVORCE", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    date_options_available: false,
    ordinal_position: 40,
    event_kind_label: "Divorce or partnership end date"
  )

QualifyingLifeEventKind.create!(
    title: "Losing other health insurance", 
    action_kind: "add_benefit",
    reason: "lost_access_to_mec",
    edi_code: "33-LOST ACCESS TO MEC", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    date_options_available: false,
    ordinal_position: 35,
    event_kind_label: 'Date of losing coverage',
    tool_tip: "Someone in the household is losing other health insurance involuntarily",
  )

QualifyingLifeEventKind.create!(
    title: "A family member has died", 
    action_kind: "drop_member",
    reason: "death",
    edi_code: "03-DEATH", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    date_options_available: false,
    ordinal_position: 45,
    event_kind_label: "Date of death",
    tool_tip: "Remove a family member due to death"
  )

QualifyingLifeEventKind.create!(
    title: "Child losing or lost coverage due to age", 
    action_kind: "drop_member",
    reason: "child_age_off",
    edi_code: "33-CHILD AGE OFF", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    date_options_available: false,
    ordinal_position: 50,
    event_kind_label: "Date of coverage loss",
    tool_tip: "Remove a child who is no longer eligible due to turning age 26"
  )

QualifyingLifeEventKind.create!(
    title: "Drop coverage due to new eligibility", 
    action_kind: "drop_member",
    reason: "new_eligibility_family",
    edi_code: "07-TERMINATION OF BENEFITS", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    date_options_available: false,
    ordinal_position: 55,
    event_kind_label: "Date of new eligibility", 
    tool_tip: "Drop coverage for myself or family member due to new eligibility for other coverage"
  )

QualifyingLifeEventKind.create!(
    title: "Drop family member due to new eligibility", 
    action_kind: "drop_member",
    reason: "new_eligibility_member",
    edi_code: "07-TERMINATION OF BENEFITS", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    date_options_available: false,
    ordinal_position: 60,
    event_kind_label: "Date of new eligibility", 
    tool_tip: "Drop coverage for a family member due to their new eligibility for other coverage"
  )

QualifyingLifeEventKind.create!(
    title: "Moved or moving",
    action_kind: "administrative",
    reason: "relocate",
    edi_code: "43-CHANGE OF LOCATION", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: false, 
    date_options_available: false,
    ordinal_position: 65,
    event_kind_label: "Date of move", 
    tool_tip: "Drop coverage due to a permanent move outside of my current plan's service area"
  )

QualifyingLifeEventKind.create!(
    title: "Exceptional circumstances", 
    action_kind: "administrative",
    reason: "exceptional_circumstances",
    edi_code: "EX-EXCEPTIONAL CIRCUMSTANCES", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: false, 
    date_options_available: false,
    ordinal_position: 70,
    event_kind_label: "Date of exceptional circumstances",
    tool_tip: "Enroll due to an inadvertent or erroneous enrollment or another exceptional circumstance"
  )

QualifyingLifeEventKind.create!(
    title: "Health plan contract violation", 
    action_kind: "administrative",
    reason: "contract_violation",
    edi_code: "33-CONTRACT VIOLATION", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: false, 
    date_options_available: true,
    ordinal_position: 75,
    event_kind_label: "Date of contract violation",
    tool_tip: "Enroll due to contract violation"
  )

QualifyingLifeEventKind.create!(
    title: "Started a new job", 
    action_kind: "add_benefit",
    reason: "new_employment",
    edi_code: "28-INITIAL ENROLLMENT", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    date_options_available: false,
    ordinal_position: 10,
    event_kind_label: 'Date of start a new job',
    tool_tip: "Enroll due to becoming newly eligibile"
  )

QualifyingLifeEventKind.create!(
    title: "Court order to provide coverage for someone",
    tool_tip: "",
    action_kind: "add_member",
    market_kind: "shop",
    event_kind_label: "Date that court orders that coverage starts",
    ordinal_position: 100,
    reason: "court_order",
    edi_code: " ",
    effective_on_kinds: ["exact_date"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 60,
    is_self_attested: false,
    date_options_available: false,
)

puts "::: QualifyingLifeEventKinds Complete :::"
puts "*"*80
