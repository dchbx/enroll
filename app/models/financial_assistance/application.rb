class FinancialAssistance::Application
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  embedded_in :tax_household_member, class_name: "::TaxHouseholdMember"

  YEARS_TO_RENEW_RANGE = 0..4
  RENEWAL_BASE_YEAR_RANGE = 2013..TimeKeeper.date_of_record.year + 1
  
  APPLICANT_KINDS   = ["user and/or family", "call center rep or case worker", "authorized representative"]
  SOURCE_KINDS      = %w(paper source in-person)
  REQUEST_KINDS     = %w()
  MOTIVATION_KINDS  = %w()

  SUBMITTED_STATUS  = %w(submitted verifying_income)


  # TODO: Need enterprise ID assignment call for Assisted Application
  field :hbx_id, type: Integer
  field :external_id, type: String
  field :integrated_case_id, type: String
  field :applicant_kind, type: String

  field :request_kind, type: String
  field :motivation_kind, type: String

  field :is_joint_tax_filing, type: Boolean
  field :eligibility_determination_id, type: BSON::ObjectId

  field :aasm_state, type: String, default: :draft
  field :submitted_at, type: DateTime

  field :assistance_year, type: Integer

  field :is_renewal_authorized, type: Boolean
  field :renewal_base_year, type: Integer
  field :years_to_renew, type: Integer

  field :us_state, type: String
  field :benchmark_plan_id, type: BSON::ObjectId

  field :medicaid_terms, type: Boolean
  field :attestation_terms, type: Boolean
  field :submission_terms, type: Boolean

  field :is_ridp_verified, type: Boolean

  embeds_many :applicants, inverse_of: :applicant, class_name: "::FinancialAssistance::Applicant"
  embeds_many :workflow_state_transitions, as: :transitional
  accepts_nested_attributes_for :applicants, :workflow_state_transitions

  validates_presence_of :hbx_id, :applicant_kind, :request_kind, :benchmark_plan_id

  # User must agree with terms of service check boxes
  validates_acceptance_of :medicaid_terms, :attestation_terms, :submission_terms

  validates :renewal_base_year, allow_nil: true,
                                numericality: { 
                                  only_integer: true,
                                  greater_than_or_equal_to: RENEWAL_BASE_YEAR_RANGE.first, 
                                  less_than_or_equal_to: RENEWAL_BASE_YEAR_RANGE.last, 
                                  message: "must fall within range: #{RENEWAL_BASE_YEAR_RANGE}" 
                                }

  validates :years_to_renew,    allow_nil: true,
                                numericality: { 
                                  only_integer: true,
                                  greater_than_or_equal_to: YEARS_TO_RENEW_RANGE.first, 
                                  less_than_or_equal_to: YEARS_TO_RENEW_RANGE.last, 
                                  message: "must fall within range: #{YEARS_TO_RENEW_RANGE}" 
                                }


  scope :submitted, ->{ any_in(aasm_state: SUBMITTED_STATUS) }

  alias_method :is_joint_tax_filing?, :is_joint_tax_filing
  alias_method :is_renewal_authorized?, :is_renewal_authorized


  # Set the benchmark plan for this financial assistance application.
  # @param benchmark_plan_id [ {Plan} ] The benchmark plan for this application.
  def benchmark_plan=(new_benchmark_plan)
    raise ArgumentError.new("expected Plan") unless new_benchmark_plan.is_a?(Plan)
    write_attribute(:benchmark_plan_id, new_benchmark_plan._id)
    @benchmark_plan = new_benchmark_plan
  end

  # Get the benchmark plan for this application.
  # @return [ {Plan} ] benchmark plan
  def benchmark_plan
    return @benchmark_plan if defined? @benchmark_plan
    @benchmark_plan = Plan.find(benchmark_plan_id) unless benchmark_plan_id.blank?
  end

  # Virtual attribute that indicates whether Primary Applicant accepts the Medicaid terms
  # of service presented at the time of application submission 
  # @return [ true, false ] true if application has reached workflow state of submitted (or later), false if not  
  def has_accepted_medicaid_terms?
    SUBMITTED_STATUS.include?(aasm_state)
  end

  # Virtual attribute that indicates whether Primary Applicant accepts the Attest terms
  # of service presented at the time of application submission 
  # @return [ true, false ] true if application has reached workflow state of submitted (or later), false if not  
  def has_accepted_attestation_terms?
    SUBMITTED_STATUS.include?(aasm_state)
  end

  # Virtual attribute that indicates whether Primary Applicant accepts the Submit terms
  # of service presented at the time of application submission 
  # @return [ true, false ] true if application has reached workflow state of submitted (or later), false if not  
  def has_accepted_submission_terms?
    SUBMITTED_STATUS.include?(aasm_state)
  end

  # Whether {User} account for Primary Applicant has succussfully completed 
  # Remote Identity Proofing (RIDP) verification process
  # @return [ true, false ] true if RIDP verification is complete, false if not 
  def is_ridp_verified?
    return @is_ridp_verified if defined?(@is_ridp_verified)
    if primary_applicant.person.user.present?
      @is_ridp_verified = primary_applicant.person.user.identity_verified?
    else
      @is_ridp_verified = false
    end
  end

  # Get the {FamilyMember} who is primary for this application.
  # @return [ {FamilyMember} ] primary {FamilyMember}
  def primary_applicant
    return @primary_applicant if defined?(@primary_applicant)
    @primary_applicant = applicants.detect { |applicant| applicant.is_primary_applicant? }
  end


  # TODO: define the states and transitions for Assisted Application workflow process
  aasm do
    state :draft, initial: true
    state :verifying_income
    state :approved
    state :denied

    event :submit, :after => :record_transition do
      transitions from: :draft, to: :draft, :guard => :is_application_valid?, :after => :report_invalid
      transitions from: :draft, to: :verifying_income, :after => :submit_application
    end

  end

  def family
    return nil unless tax_household_member
    tax_household_member.family
  end

  def applicant
    return nil unless tax_household_member
    tax_household_member.family_member
  end

  def eligibility_determination=(ed_instance)
    return unless ed_instance.is_a? EligibilityDetermination
    self.eligibility_determination_id = ed_instance._id
    @eligibility_determination = ed_instance
  end

  def eligibility_determination
    return nil unless tax_household_member
    return @eligibility_determination if defined? @eligibility_determination
    @eligibility_determination = tax_household_member.eligibility_determinations.detect { |elig_d| elig_d._id == self.eligibility_determination_id }
  end

  # Evaluate if receiving Alternative Benefits this year
  def is_receiving_benefit?
    return_value = false

    alternate_benefits.each do |alternate_benefit|
      return_value = is_receiving_benefits_this_year?(alternate_benefit)
      break if return_value
    end

    return return_value
  end

##### Methods below were transferred from EDI DB system
##### TODO: verify utility and improve names

  def compute_yearwise(incomes_or_deductions)
    income_deduction_per_year = Hash.new(0)

    incomes_or_deductions.each do |income_deduction|
      working_days_in_year = Float(52*5)
      daily_income = 0

      case income_deduction.frequency
        when "daily"
          daily_income = income_deduction.amount_in_cents
        when "weekly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year/52)
        when "biweekly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year/26)
        when "monthly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year/12)
        when "quarterly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year/4)
        when "half_yearly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year/2)
        when "yearly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year)
      end

      income_deduction.start_date = TimeKeeper.date_of_record.beginning_of_year if income_deduction.start_date.to_s.eql? "01-01-0001" || income_deduction.start_date.blank?
      income_deduction.end_date   = TimeKeeper.date_of_record.end_of_year if income_deduction.end_date.to_s.eql? "01-01-0001" || income_deduction.end_date.blank?
      years = (income_deduction.start_date.year..income_deduction.end_date.year)

      years.to_a.each do |year|
        actual_days_worked = compute_actual_days_worked(year, income_deduction.start_date, income_deduction.end_date)
        income_deduction_per_year[year] += actual_days_worked * daily_income
      end
    end

    income_deduction_per_year.merge(income_deduction_per_year) { |k, v| Integer(v) rescue v }
  end

  # Compute the actual days a person worked during one year
  def compute_actual_days_worked(year, start_date, end_date)
    working_days_in_year = Float(52*5)

    if Date.new(year, 1, 1) < start_date
      start_date_to_consider = start_date
    else
      start_date_to_consider = Date.new(year, 1, 1)
    end

    if Date.new(year, 1, 1).end_of_year < end_date
      end_date_to_consider = Date.new(year, 1, 1).end_of_year
    else
      end_date_to_consider = end_date
    end

    # we have to add one to include last day of work. We multiply by working_days_in_year/365 to remove weekends.
    ((end_date_to_consider - start_date_to_consider + 1).to_i * (working_days_in_year/365)).to_i #actual days worked in 'year'
  end

  def is_receiving_benefits_this_year?(alternate_benefit)
    alternate_benefit.start_date = TimeKeeper.date_of_record.beginning_of_year if alternate_benefit.start_date.blank?
    alternate_benefit.end_date =   TimeKeeper.date_of_record.end_of_year if alternate_benefit.end_date.blank?
    (alternate_benefit.start_date.year..alternate_benefit.end_date.year).include? TimeKeeper.date_of_record.year
  end

  def total_incomes_by_year
    incomes_by_year = compute_yearwise(incomes)
    deductions_by_year = compute_yearwise(deductions)

    years = incomes_by_year.keys | deductions_by_year.keys

    total_incomes = {}

    years.each do |y|
      income_this_year = incomes_by_year[y] || 0
      deductions_this_year = deductions_by_year[y] || 0
      total_incomes[y] = (income_this_year - deductions_this_year) * 0.01
    end
    total_incomes
  end

private
  def set_submission_date
    write_attribute(:submitted_at, TimeKeeper.datetime_of_record)
  end

  def is_application_valid?
  end


end
