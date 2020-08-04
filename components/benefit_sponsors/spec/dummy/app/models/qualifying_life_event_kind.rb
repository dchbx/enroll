class QualifyingLifeEventKind
  include Mongoid::Document
  include Mongoid::Timestamps
  include Config::AcaModelConcern

  ACTION_KINDS = %w[add_benefit add_member drop_member change_benefit terminate_benefit administrative]
  MarketKinds = %w[shop]

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
  field :is_visible, type: Mongoid::Boolean
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
            allow_nil:   false,
            inclusion: {in: MarketKinds}

  validates_presence_of :title, :market_kind, :effective_on_kinds, :pre_event_sep_in_days,
                        :post_event_sep_in_days

  scope :active, ->{ where(is_active: true).where(:created_at.ne => nil).order(ordinal_position: :asc) }


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
    end
    coverage_effective_on
  end

  def is_dependent_loss_of_coverage?
    %w(employee_gaining_medicare employer_sponsored_coverage_termination).include? reason
  end

  def is_moved_to_dc?
    #title == "I'm moving to the District of Columbia"
    reason == 'relocate'
  end

  def shop?
    market_kind == "shop"
  end

  def family_structure_changed?
    #["I've had a baby", "I've adopted a child", "I've married", "I've divorced or ended domestic partnership", "I've entered into a legal domestic partnership"].include? title
    %w(birth adoption marriage divorce domestic_partnership).include? reason
  end

  def is_loss_of_other_coverage?
    reason == "lost_access_to_mec"
  end

  class << self
    def shop_market_events
      where(:market_kind => "shop").and(:is_visible.ne => false).active.to_a
    end

    def shop_market_events_admin
      where(:market_kind => "shop").active.to_a
    end

    def shop_market_non_self_attested_events
      where(:market_kind => "shop").and(:is_visible.ne => true).active.to_a
    end
  end

  def date_hint
    start_date = TimeKeeper.date_of_record - post_event_sep_in_days.try(:days)
    end_date = TimeKeeper.date_of_record + pre_event_sep_in_days.try(:days)
      "(must fall between #{start_date.strftime("%B %d")} and #{end_date.strftime("%B %d")})"
  end
end
