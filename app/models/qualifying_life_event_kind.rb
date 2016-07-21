class QualifyingLifeEventKind
  include Mongoid::Document
	include Mongoid::Timestamps

  # Model Changes to support IVL needs
  ## effective_on_kinds -- type changed to Array to support multiple choices (view to provide choice when size > 1)
  ### added enumerations to EffectiveOnKinds with following definitions:
  ###   exact_date: specific date provided
  ###   date_of_event: specific date upon which the QLE occurred
  ###   first_of_month: first of month following the 15th of month rule
  ###   first_of_next_month: first day of month, not subject to 15th of month rule
  ###   fixed_first_of_next_month: first of month immediately following date of event (is not relative to when the person plan shops)
  ## populated reason code in some instances -- use to call class method for business rules when present
  ## ordinal_position -- set and use these values to determine sort order in view
  ## added event_on -- property to store date on which QLE event occured
  ## added event_kind_label -- use to populate label for collecting event_on date
  ## renamed property: kind to action_kind (also renamed associated constant)


  ACTION_KINDS = %w[add_benefit add_member drop_member change_benefit terminate_benefit administrative]
  MarketKinds = %w[shop individual]

  # first_of_next_month: not subject to 15th of month effective date rule
  EffectiveOnKinds = %w(date_of_event first_of_month first_of_next_month fixed_first_of_next_month exact_date)

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
  ]

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

  # validates :effective_on_kinds,
  #           presence: true,
  #           allow_blank: false,
  #           allow_nil:   false,
  #           inclusion: {in: EffectiveOnKinds}

  validates :market_kind,
            presence: true,
            allow_blank: false,
            allow_nil:   false,
            inclusion: {in: MarketKinds}

  # before_create :activate_household_sep
  # before_save :activate_household_sep
  validates_presence_of :title, :market_kind, :effective_on_kinds, :pre_event_sep_in_days,
                        :post_event_sep_in_days

  scope :active, ->{ where(is_active: true).where(:created_at.ne => nil).order(ordinal_position: :asc) }

  # Business rules for EmployeeGainingMedicare
  # If coverage ends on last day of month and plan selected before loss of coverage:
  #   effective date is first day of the month after other coverage will end
  # If coverage ends on last day of month and plan selected after loss of other coverage:
  #   effective date is first day of the month following plan selection (not following 15th of month rule)
  # If coverage ends on date other than last day of the month and plan selected during or after the month in which coverage ends:
  #   effective date is 1st of the month following plan selection
  # If coverage ends on date other than last day of month and plan selected before the month in which coverage ends:
  #   effective date is consumer chooses between 1st of the month when coverage ends (allowing overlap - but no APTC for overlapping month)
  #   or the first of the month following the month when coverage ends
  def employee_gaining_medicare(coverage_end_on, selected_effective_on = nil, consumer_coverage_effective_on = nil)
    coverage_end_last_day_of_month = Date.new(coverage_end_on.year, coverage_end_on.month, coverage_end_on.end_of_month.day)
    if coverage_end_on == coverage_end_last_day_of_month
      if TimeKeeper.date_of_record <= coverage_end_on
        coverage_effective_on = coverage_end_last_day_of_month + 1.day
      else
        coverage_effective_on = TimeKeeper.date_of_record.end_of_month + 1.day
      end
    else
      if TimeKeeper.date_of_record <= (coverage_end_last_day_of_month - 1.month).end_of_month
        coverage_effective_on = if selected_effective_on.blank?
                                  [coverage_end_on.beginning_of_month, coverage_end_last_day_of_month + 1.day]
                                else
                                  selected_effective_on
                                end
      else
        coverage_effective_on = TimeKeeper.date_of_record.end_of_month + 1.day
      end

      #FIXME what's this consumer_coverage_effective_on for, this is no rules for EmployeeGainingMedicare to allowd consumer to choose a particular timing.
      #if (consumer_coverage_effective_on >= coverage_end_on.first_of_month) &&
      #  (consumer_coverage_effective_on <= (coverage_end_on.first_of_month + 1.month))
      #  coverage_effective_on = consumer_coverage_effective_on
      #else
      #  # raise invalid effective date error
      #end
    end
    coverage_effective_on
  end

  # Business rules for MoveToState
  ## The effective date should be the first day of the month following plan selection, but no earlier than the date of the move
  def move_to_state(move_date)
    # raise_error if move_date > TimeKeeper.date_of_record.end_of_month + 1.day
  end

  def is_dependent_loss_of_coverage?
    #["Losing Employer-Subsidized Insurance because employee is going on Medicare", "My employer did not pay my premiums on time"].include? title
    #lost_access_to_mec
    %w(employee_gaining_medicare employer_sponsored_coverage_termination).include? reason
  end

  def is_moved_to_dc?
    #title == "I'm moving to the District of Columbia"
    reason == 'relocate'
  end

  def individual?
    market_kind == "individual"
  end

  def family_structure_changed?
    #["I've had a baby", "I've adopted a child", "I've married", "I've divorced or ended domestic partnership", "I've entered into a legal domestic partnership"].include? title
    %w(birth adoption marriage divorce domestic_partnership).include? reason
  end

  class << self
    def shop_market_events
      where(:market_kind => "shop").and(:is_self_attested.ne => false).active.to_a
    end

    def individual_market_events
      where(:market_kind => "individual").and(:is_self_attested.ne => false).active.to_a
    end

    def shop_market_events_admin
      where(:market_kind => "shop").active.to_a
    end

    def individual_market_events_admin
      where(:market_kind => "individual").active.to_a
    end
  end

end
