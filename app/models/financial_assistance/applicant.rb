class FinancialAssistance::Applicant
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :application

  TAX_FILER_KINDS = %W(tax_filer single joint separate dependent non_filer)
  STUDENT_KINDS = %w()
  STUDENT_SCHOOL_KINDS = %w()

  field :has_fixed_address, type: Boolean, default: true
  field :is_living_in_state, type: Boolean, default: true
  field :is_temp_out_of_state, type: Boolean, default: false

  field :is_required_to_file_taxes, type: Boolean, default: true
  field :tax_filer_kind, type: String, default: "tax_filer"
  field :is_joint_tax_filing, type: Boolean, default: false
  field :is_claimed_as_tax_dependent, type: Boolean

  field :is_ia_eligible, type: Boolean, default: false
  field :is_medicaid_chip_eligible, type: Boolean, default: false
  field :is_medicare_eligible, type: Boolean, default: false

  field :is_student, type: Boolean, default: false
  field :student_kind, type: String
  field :student_school_kind, type: String
  field :student_status_end_on, type: String

  field :is_self_attested_blind_or_disabled, type: Boolean, default: false
  field :is_self_attested_long_term_care, type: Boolean, default: false

  field :is_veteran, type: Boolean, default: false
  field :is_refugee, type: Boolean, default: false
  field :is_trafficking_victim, type: Boolean, default: false

  field :is_former_foster_care, type: Boolean, default: false
  field :age_left_foster_care, type: Integer, default: 0
  field :foster_care_us_state, type: String
  field :had_medicaid_during_foster_care, type: Boolean, default: false

  field :is_pregnant, type: Boolean, default: false
  field :is_post_partum_period, type: Boolean, default: false
  field :children_expected_count, type: Integer, default: 0
  field :pregnancy_due_on, type: Date
  field :pregnancy_end_on, type: Date

  field :is_subject_to_five_year_bar, type: Boolean, default: false
  field :is_five_year_bar_met, type: Boolean, default: false
  field :is_forty_quarters, type: Boolean, default: false

  field :non_ssn_apply_reason, type: Boolean

  # 5 Yr. Bar QNs.
  field :moved_on_or_after_welfare_reformed_law, type: Boolean
  field :is_veteran_or_active_military, type: Boolean
  field :is_spouse_or_dep_child_of_veteran_or_active_military, type: Boolean
  field :is_currently_enrolled_in_health_plan, type: Boolean

  embeds_many :incomes,     inverse_of: :income,     class_name: "::FinancialAssistance::Income"
  embeds_many :deductions,  inverse_of: :deduction,  class_name: "::FinancialAssistance::Deduction"
  embeds_many :benefits,    inverse_of: :benefit,    class_name: "::FinancialAssistance::Benefit"

  accepts_nested_attributes_for :incomes, :deductions, :benefits

  validates_presence_of :has_fixed_address

  validates :tax_filer_kind,
    inclusion: { in: TAX_FILER_KINDS, message: "%{value} is not a valid tax filer kind" },
    allow_blank: true

  alias_method :is_ia_eligible?, :is_ia_eligible
  alias_method :is_medicaid_chip_eligible?, :is_medicaid_chip_eligible
  alias_method :is_medicare_eligible?, :is_medicare_eligible
  alias_method :is_joint_tax_filing?, :is_joint_tax_filing

  def is_tax_dependent?
    tax_filer_kind.present? && tax_filer_kind == "tax_dependent"
  end

  #### Use Person.consumer_role values for following
  def is_us_citizen?
  end

  def is_amerasian?
  end

  def is_native_american?
  end

  def citizen_status?
  end

  def lawfully_present?
  end

  def immigration_status?
  end

  def immigration_date?
  end

  #### Collect insurance from Benefit model
  def has_insurance?
  end

  def had_prior_insurance?
  end

  def prior_insurance_end_date?
  end

  def has_state_health_benefit?
  end

  # Has access to employer-sponsored coverage that meets ACA minimum standard value and
  #   employee responsible premium amount is <= 9.5% of Household income
  def has_employer_sponsored_coverage?
  end

  def is_without_assistance?
  end

  def is_primary_applicant?
    family_member.is_primary_applicant?
  end

  def family_member
    return @family_member if defined?(@family_member)
    @family_member = family_members.detect { |member| member.is_primary_applicant? }
  end

  def consumer_role
    return @consumer_role if defined?(@consumer_role)
    @consumer_role = person.consumer_role
  end

  def person
    return @person if defined?(@person)
    @person = family_member.person
  end

  # Use income entries to determine hours worked
  def total_hours_worked_per_week
    incomes.reduce(0) { |sum_hours, income| sum_hours + income.hours_worked_per_week }
  end

  def tobacco_user
    person.is_tobacco_user || "unknown"
  end

end
