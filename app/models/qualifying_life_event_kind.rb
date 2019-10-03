# frozen_string_literal: true

class QualifyingLifeEventKind
  include Mongoid::Document
  include Mongoid::Timestamps
  include Config::AcaModelConcern

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

  ACTION_KINDS = %w[add_benefit add_member drop_member change_benefit terminate_benefit administrative transition_member]
  MARKET_KINDS = %w[shop individual fehb].freeze

  # first_of_next_month: not subject to 15th of month effective date rule
  EffectiveOnKinds = %w(date_of_event first_of_month first_of_next_month fixed_first_of_next_month exact_date)

  EffectiveOnKindsWithCode = QualifyingLifeEventKind::EffectiveOnKinds.dup.map { |effective_on_kind| { name: effective_on_kind.humanize.titleize, code: effective_on_kind } }

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
    "exceptional_circumstances",
    "eligibility_failed_or_documents_not_received_by_due_date",
    "eligibility_documents_provided"
  ]

  DEFAULT_QUALIFYING_LIFE_EVENTS = [
    "Started a new job",
    "Married",
    "Entered into a legal domestic partnership",
    "Had a baby",
    "Adopted a child",
    "Losing other health insurance",
    "Divorced",
    "A family member has died",
    "Child losing or lost coverage due to age",
    "Drop coverage due to new eligibility",
    "Drop family member due to new eligibility",
    "Moved or moving",
    "Exceptional circumstances",
    "Health plan contract violation",
    "Court order to provide coverage for someone"
  ]
  

  embeds_many :custom_qle_questions, as: :questionable


  field :event_kind_label, type: String
  field :action_kind, type: String

  field :title, type: String
  field :action_kind, type: String
  field :effective_on_kinds, type: Array, default: []
  field :reason, type: String
  field :edi_code, type: String
  field :market_kind, type: String # Deprecated
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
  field :visibility, type: Symbol
  field :visible_to_customer, type: Mongoid::Boolean, default: false

  index({action_kind: 1})
  index({market: 1, ordinal_position: 1 })
  index({start_on: 1, end_on: 1})

  accepts_nested_attributes_for :custom_qle_questions

  # validates :effective_on_kinds,
  #           presence: true,
  #           allow_blank: false,
  #           allow_nil:   false,
  #           inclusion: {in: EffectiveOnKinds}

  validates :market_kind,
            presence: true,
            allow_blank: false,
            allow_nil:   false,
            inclusion: {in: MARKET_KINDS}

  # before_create :activate_household_sep
  # before_save :activate_household_sep
  validates_presence_of :title, :market_kind, :effective_on_kinds, :pre_event_sep_in_days,
                        :post_event_sep_in_days

  scope :active, ->{ where(is_active: true).where(:created_at.ne => nil).order(ordinal_position: :asc) }
  # TODO: This scope should be update depdning on what the business definition of deactivation is
  # At the moment, setting 'end on' is how they are deactivated.
  scope :not_set_for_deactivation, ->{ where(end_on: nil).sort_by_title_alphabetical }
  scope :sort_by_title_alphabetical, ->{ order('title ASC') }
  scope :by_market_kind, ->(market_kind){ where(market_kind: market_kind) }
  scope :within_current_start_on_end_on_dates, -> {
    where(start_on: {"$lte" => TimeKeeper.date_of_record}, end_on: { "$gte" => TimeKeeper.date_of_record})
  }
  # Active vs visible_to_customer:
  # In the current UI scopes in the QLEKind model,
  # the scopes appearing to the end user have
  # is_active set to true and are creatd with is_active = true by default.
  # To non intrusively bring in
  # the Custom Qle kinds, the new attribute visible_to_customer
  # was added. That way, Custom QLE Kinds will only appear on the UI
  # when they're confirmed as ready by business and visible_to_customer = true
  scope :is_visible_to_customer, -> { where(visible_to_customer: true) }
  # TODO: Need to determine what this scope should be. Perhaps all QLE Kinds should be
  # editable. Or perhaps there needs to be a new action to determine their visibility
  # to the customer, and only those where is_visible_to_customer set to false should be
  # editable.
  scope :editable, ->{where(is_active: false)}


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

  # Example of this is "Date that feds order that coverage starts". If not present, just show "Date of Event."
  def show_event_kind_label_if_present
    event_kind_label.to_s.length > 0 ? event_kind_label.to_s + ":" : "Date of Event:" 
  end

  def is_moved_to_dc?
    #title == "I'm moving to the District of Columbia"
    reason == 'relocate'
  end

  def individual?
    market_kind == "individual"
  end

  def shop?
    market_kind == "shop"
  end

  def fehb?
    market_kind == "fehb"
  end

  def family_structure_changed?
    #["I've had a baby", "I've adopted a child", "I've married", "I've divorced or ended domestic partnership", "I've entered into a legal domestic partnership"].include? title
    %w(birth adoption marriage divorce domestic_partnership).include? reason
  end

  def is_loss_of_other_coverage?
    reason == "lost_access_to_mec"
  end

  # TODO: This can be updated depending on business requirements
  def qle_dropdown_label
    edi_code.to_s + " | " + title.to_s
  end

  class << self
    def shop_market_events
      by_market_kind('shop').and(:is_self_attested.ne => false).is_visible_to_customer.within_current_start_on_end_on_dates.to_a
    end

    def shop_market_events_admin
      by_market_kind('shop').is_visible_to_customer.within_current_start_on_end_on_dates.to_a
    end

    def shop_market_non_self_attested_events
      by_market_kind('shop').and(:is_self_attested.ne => true).is_visible_to_customer.within_current_start_on_end_on_dates.to_a
    end

    def fehb_market_events
      by_market_kind('fehb').and(:is_self_attested.ne => false).is_visible_to_customer.within_current_start_on_end_on_dates.to_a
    end

    def fehb_market_events_admin
      by_market_kind('fehb').is_visible_to_customer.within_current_start_on_end_on_dates.to_a
    end

    def fehb_market_non_self_attested_events
      by_market_kind('fehb').and(:is_self_attested.ne => true).is_visible_to_customer.within_current_start_on_end_on_dates.to_a
    end

    def individual_market_events
      by_market_kind('individual').and(:is_self_attested.ne => false).is_visible_to_customer.within_current_start_on_end_on_dates.to_a
    end

    def individual_market_events_admin
      by_market_kind('individual').is_visible_to_customer.within_current_start_on_end_on_dates.to_a
    end

    def individual_market_non_self_attested_events
      by_market_kind('individual').and(:is_self_attested.ne => true).is_visible_to_customer.within_current_start_on_end_on_dates.to_a
    end

    def individual_market_events_without_transition_member_action
      by_market_kind('individual').is_visible_to_customer.within_current_start_on_end_on_dates.to_a.reject {|qle| qle.action_kind == "transition_member"}
    end

    def qualifying_life_events_for(role, hbx_staff = false)
      return [] if role.blank?

      market_kind = 'shop'
      market_kind = 'individual' if role.is_a?(ConsumerRole) || role.is_a?(ResidentRole)
      market_kind = 'fehb' if role.is_a?(EmployeeRole) && role.employer_profile.is_a?(BenefitSponsors::Organizations::FehbEmployerProfile)
      if hbx_staff
        send(market_kind + '_market_events_admin')
      else
        send(market_kind + '_market_events')
      end
    end
  end

  def date_hint
    start_date = TimeKeeper.date_of_record - post_event_sep_in_days.try(:days)
    end_date = TimeKeeper.date_of_record + pre_event_sep_in_days.try(:days)
      "(must fall between #{start_date.strftime("%B %d")} and #{end_date.strftime("%B %d")})"
  end
end
