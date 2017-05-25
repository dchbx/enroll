class FinancialAssistance::Benefit
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :application, class_name: "::FinancialAssistance::Application"

  TITLE_SIZE_RANGE = 3..30
  STATE_HEALTH_BENEFITS = %w(medicaid)

  KINDS = %W(
      acf_refugee_medical_assistance
      americorps_health_benefits
      child_health_insurance_plan
      medicaid
      medicare
      medicare_advantage
      medicare_part_b
      private_individual_and_family_coverage
      state_supplementary_payment
      tricare
      veterans_benefits
      naf_health_benefit_program
      health_care_for_peace_corp_volunteers
      state_supplementary_payment
      department_of_defense_non_appropriated_health_benefits
    )

  field :title, type: String
  field :kind, type: String

  field :is_employer_sponsored, type: Boolean
  field :is_eligible, type: Boolean
  field :is_enrolled, type: Boolean
  field :employee_cost, type: String
  field :employee_cost_frequency, type: String

  field :start_on, type: Date
  field :end_on, type: Date
  field :submitted_at, type: DateTime

  validates :start_on, presence: true

  validates_length_of :title, 
                      in: TITLE_SIZE_RANGE, 
                      allow_nil: true,
                      message: "pick a name length between #{TITLE_SIZE_RANGE}"

  validates :kind,    presence: true, 
                      inclusion: { 
                        in: KINDS, 
                        message: "%{value} is not a valid alternative benefit type" 
                      }

  validate :start_on_must_precede_end_on

  before_create :set_submission_timestamp

  alias_method :is_employer_sponsored?, :is_employer_sponsored
  alias_method :is_eligible?, :is_eligible
  alias_method :is_enrolled?, :is_enrolled

  # Eligibility through public employee
  def is_state_health_benefit?
  end


private

  def set_submission_timestamp
    write_attribute(:submitted_at, TimeKeeper.datetime_of_record) if submitted_at.blank?
  end

  def start_on_must_precede_end_on
    return unless start_on.present? && end_on.present?
    errors.add(:end_on, "can't occur before start on date") if end_on < start_on
  end

end