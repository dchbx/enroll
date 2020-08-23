# frozen_string_literal: true

# rubocop:disable Naming/ConstantName

class QualifyingLifeEventKind
  include Mongoid::Document
  include Mongoid::Timestamps
  include Config::AcaModelConcern

  ACTION_KINDS = %w[add_benefit add_member drop_member change_benefit terminate_benefit administrative].freeze
  MarketKinds = %w[shop].freeze

  EffectiveOnKinds = %w[date_of_event first_of_month first_of_next_month fixed_first_of_next_month exact_date].freeze

  REASON_KINDS = [
    "lost_access_to_mec",
    "adoption",
    "birth",
    "marriage",
    "domestic_partnership",
    "divorce",
    "death",
    "child_age_off",
    "relocate",
    "new_eligibility_member",
    "new_eligibility_family",
    "termination_of_benefits",
    "termination_of_employment",
    "new_employment",
    "employer_sponsored_coverage_termination",
    "employee_gaining_medicare",
    "enrollment_error_or_misconduct_hbx",
    "enrollment_error_or_misconduct_issuer",
    "enrollment_error_or_misconduct_non_hbx",
    "contract_violation",
    "court_order",
    "eligibility_change_income",
    "eligibility_change_immigration_status",
    "eligibility_change_medicaid_ineligible",
    "eligibility_change_employer_ineligible",
    "lost_hardship_exemption",
    "qualified_native_american",
    "exceptional_circumstances_natural_disaster",
    "exceptional_circumstances_medical_emergency",
    "exceptional_circumstances_system_outage",
    "exceptional_circumstances_domestic_abuse",
    "exceptional_circumstances_civic_service",
    "exceptional_circumstances"
  ].freeze

  field :event_kind_label, type: String
  field :action_kind, type: String

  field :title, type: String
  field :action_kind, type: String
  field :effective_on_kinds, type: Array, default: []
  field :reason, type: String
  field :edi_code, type: String
  field :market_kind, type: String
  field :tool_tip, type: String
  field :pre_event_sep_in_days, type: Integer
  field :is_self_attested, type: Mongoid::Boolean
  field :date_options_available, type: Mongoid::Boolean
  field :post_event_sep_in_days, type: Integer
  field :ordinal_position, type: Integer

  field :is_active, type: Boolean, default: true
  field :event_on, type: Date
  field :coverage_effective_on, type: Date
  field :start_on, type: Date
  field :end_on, type: Date


  index({action_kind: 1})
  index({market: 1, ordinal_position: 1 })
  index({start_on: 1, end_on: 1})

  validates :market_kind,
            presence: true,
            allow_blank: false,
            allow_nil: false,
            inclusion: {in: MarketKinds}

  validates_presence_of :title, :market_kind, :effective_on_kinds, :pre_event_sep_in_days,
                        :post_event_sep_in_days

  scope :active, ->{ where(is_active: true).where(:created_at.ne => nil).order(ordinal_position: :asc) }
end

# rubocop:enable Naming/ConstantName

