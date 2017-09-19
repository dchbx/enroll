class FinancialAssistance::Applicant
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :application

  TAX_FILER_KINDS = %W(tax_filer single joint separate dependent non_filer)
  STUDENT_KINDS = %w(
    dropped_out
    elementary
    english_language_institute
    full_time
    ged
    graduated
    graduate_school
    half_time
    junior_school
    not_in_school
    open_university
    part_time
    preschool
    primary
    secondary
    technical
    undergraduate
    vocational
    vocational_tech
  )

  STUDENT_SCHOOL_KINDS = %w(
    english_language_institute
    elementary
    equivalent_vocational_tech
    graduate_school
    ged
    high_school
    junior_school
    open_university
    pre_school
    primary
    technical
    undergraduate
    vocational
  )
  field :family_member_id, type: BSON::ObjectId
  field :tax_household_id, type: BSON::ObjectId

  field :is_active, type: Boolean, default: true

  field :has_fixed_address, type: Boolean, default: true
  field :is_living_in_state, type: Boolean, default: true
  field :is_temp_out_of_state, type: Boolean, default: false

  field :is_required_to_file_taxes, type: Boolean
  field :tax_filer_kind, type: String, default: "tax_filer" # change to the response of is_required_to_file_taxes && is_joint_tax_filing
  field :is_joint_tax_filing, type: Boolean
  field :is_claimed_as_tax_dependent, type: Boolean
  field :claimed_as_tax_dependent_by, type: BSON::ObjectId

  field :is_ia_eligible, type: Boolean, default: false
  field :is_medicaid_chip_eligible, type: Boolean, default: false
  field :is_non_magi_medicaid_eligible, type: Boolean, default: false
  field :is_totally_ineligible, type: Boolean, default: false
  field :is_without_assistance, type: Boolean, default: false

  field :magi_medicaid_monthly_household_income, type: Money, default: 0.00
  field :magi_medicaid_monthly_income_limit, type: Money, default: 0.00

  field :magi_as_percentage_of_fpl, type: Float, default: 0.0
  field :magi_medicaid_type, type: String
  field :magi_medicaid_category, type: String
  field :medicaid_household_size, type: Integer

  # We may not need the following two fields
  field :is_magi_medicaid, type: Boolean, default: false
  field :is_medicare_eligible, type: Boolean, default: false

  field :is_student, type: Boolean
  field :student_kind, type: String
  field :student_school_kind, type: String
  field :student_status_end_on, type: String

  #split this out : change XSD too.
  #field :is_self_attested_blind_or_disabled, type: Boolean, default: false
  field :is_self_attested_blind, type: Boolean
  field :is_self_attested_disabled, type: Boolean, default: false

  field :is_self_attested_long_term_care, type: Boolean, default: false

  field :is_veteran, type: Boolean, default: false
  field :is_refugee, type: Boolean, default: false
  field :is_trafficking_victim, type: Boolean, default: false

  field :is_former_foster_care, type: Boolean
  field :age_left_foster_care, type: Integer, default: 0
  field :foster_care_us_state, type: String
  field :had_medicaid_during_foster_care, type: Boolean

  field :is_pregnant, type: Boolean
  field :is_enrolled_on_medicaid, type: Boolean
  field :is_post_partum_period, type: Boolean
  field :children_expected_count, type: Integer, default: 0
  field :pregnancy_due_on, type: Date
  field :pregnancy_end_on, type: Date

  field :is_subject_to_five_year_bar, type: Boolean, default: false
  field :is_five_year_bar_met, type: Boolean, default: false
  field :is_forty_quarters, type: Boolean, default: false

  field :is_ssn_applied, type: Boolean
  field :non_ssn_apply_reason, type: String

  # 5 Yr. Bar QNs.
  field :moved_on_or_after_welfare_reformed_law, type: Boolean
  field :is_veteran_or_active_military, type: Boolean
  field :is_spouse_or_dep_child_of_veteran_or_active_military, type: Boolean #remove redundant field
  field :is_currently_enrolled_in_health_plan, type: Boolean

  # Other QNs.
  field :has_daily_living_help, type: Boolean
  field :need_help_paying_bills, type: Boolean
  field :is_resident_post_092296, type: Boolean
  field :is_vets_spouse_or_child, type: Boolean

  # Driver QNs.
  field :has_job_income, type: Boolean
  field :has_self_employment_income, type: Boolean
  field :has_other_income, type: Boolean
  field :has_deductions, type: Boolean
  field :has_enrolled_health_coverage, type: Boolean
  field :has_eligible_health_coverage, type: Boolean

  field :workflow, type: Hash, default: { }

  default_scope -> {where(:is_active => true)}
  
  embeds_many :incomes,     class_name: "::FinancialAssistance::Income"
  embeds_many :deductions,  class_name: "::FinancialAssistance::Deduction"
  embeds_many :benefits,    class_name: "::FinancialAssistance::Benefit"

  accepts_nested_attributes_for :incomes, :deductions, :benefits

  validate :presence_of_attr_step_1, on: :step_1
  validate :presence_of_attr_step_2, on: :step_2
  validate :presence_of_attr_other_qns, on: :other_qns
  validates :validate_applicant_information, presence: true, on: :submission

  validate :strictly_boolean

  validates :tax_filer_kind,
    inclusion: { in: TAX_FILER_KINDS, message: "%{value} is not a valid tax filer kind" },
    allow_blank: true

  alias_method :is_ia_eligible?, :is_ia_eligible
  alias_method :is_medicaid_chip_eligible?, :is_medicaid_chip_eligible
  alias_method :is_medicare_eligible?, :is_medicare_eligible
  alias_method :is_joint_tax_filing?, :is_joint_tax_filing

  after_update :delete_embedded_documents_on_driver_qns_update
  after_update :create_embedded_documents_on_driver_qns_update

  def is_ia_eligible?
    is_ia_eligible
  end

  def is_medicaid_chip_eligible?
    is_medicaid_chip_eligible
  end

  def is_tax_dependent?
    tax_filer_kind.present? && tax_filer_kind == "tax_dependent"
  end

  def strictly_boolean
    unless is_ia_eligible.is_a? Boolean
      self.errors.add(:base, "is_ia_eligible should be a boolean")
    end

    unless is_medicaid_chip_eligible.is_a? Boolean
      self.errors.add(:base, "is_medicaid_chip_eligible should be a boolean")
    end
  end

  def tax_filing?
    is_required_to_file_taxes
  end

  def is_claimed_as_tax_dependent?
    is_claimed_as_tax_dependent
  end

  def is_not_in_a_tax_household?
    self.tax_household.blank?
  end

  def has_spouse
    application.family.primary_applicant.person.person_relationships.where(kind: 'spouse').first.present? ? true : false
  end

  def tax_household_of_spouse
    spouse_relationship  = self.person.person_relationships.where(kind: 'spouse').first
    if spouse_relationship.present?
      spouse = Person.find(spouse_relationship.successor_id)
      spouse_applicant = application.applicants.detect {|applicant| spouse == applicant.person }
      return spouse_applicant.tax_household
    end
    return nil
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
    person.citizen_status
  end

  def immigration_date?
  end

  #### Collect insurance from Benefit model
  def is_enrolled_in_insurance?
    benefits.where(kind: 'is_enrolled').present?
  end

  def is_eligible_for_insurance?
    benefits.where(kind: 'is_eligible').present?
  end

  def had_prior_insurance?
  end

  def prior_insurance_end_date
  end

  def has_state_health_benefit?
    benefits.where(insurance_kind: 'medicaid').present?
  end

  # Has access to employer-sponsored coverage that meets ACA minimum standard value and
  #   employee responsible premium amount is <= 9.5% of Household income
  def has_employer_sponsored_coverage?
    benefits.where(insurance_kind: 'employer_sponsored_insurance').present?
  end

  def is_without_assistance?
    is_without_assistance
  end

  def is_primary_applicant?
    family_member.is_primary_applicant?
  end

  def family_member
    @family_member ||= FamilyMember.find(family_member_id)
  end

  def consumer_role
    return @consumer_role if defined?(@consumer_role)
    @consumer_role = person.consumer_role
  end

  def person
    @person ||= family_member.person
  end

  # Use income entries to determine hours worked
  def total_hours_worked_per_week
    incomes.reduce(0) { |sum_hours, income| sum_hours + income.hours_worked_per_week }
  end

  def tobacco_user
    person.is_tobacco_user || "unknown"
  end

  def family
    family_member.family
  end

  def tax_household=(thh)
    self.tax_household_id = thh.id
  end

  def tax_household
    return nil unless tax_household_id
    self.application.tax_households.find(tax_household_id)
  end

  def age_on_effective_date
    return @age_on_effective_date unless @age_on_effective_date.blank?
    dob = family_member.person.dob
    coverage_start_on = Forms::TimeKeeper.new.date_of_record
    return unless coverage_start_on.present?
    age = coverage_start_on.year - dob.year

    # Shave off one year if coverage starts before birthday
    if coverage_start_on.month == dob.month
      age -= 1 if coverage_start_on.day < dob.day
    else
      age -= 1 if coverage_start_on.month < dob.month
    end

    @age_on_effective_date = age
  end

  def eligibility_determinations
    return nil unless tax_household
    tax_household.eligibility_determinations
  end

  def preferred_eligibility_determination
    return nil unless tax_household
    tax_household.preferred_eligibility_determination
  end

  def applicant_validation_complete?
    self.valid?(:submission) &&
      self.incomes.all? { |income| income.valid? :submission } &&
      self.benefits.all? { |benefit| benefit.valid? :submission } &&
      self.deductions.all? { |deduction| deduction.valid? :submission }
  end

  def clean_conditional_params(model_params)
    clean_params(model_params)
  end

  def age_of_the_applicant
    age_of_applicant
  end

  def other_questions_complete?
    !has_daily_living_help.nil? &&
      !need_help_paying_bills.nil? &&
      !is_resident_post_092296.nil? &&
      !is_vets_spouse_or_child.nil?
  end

  def tax_info_complete?
    !is_required_to_file_taxes.nil? &&
      !is_claimed_as_tax_dependent.nil?
  end

  def incomes_complete?
    self.incomes.all? do |income|
      income.valid? :submission
    end
  end

  def benefits_complete?
    self.benefits.all? do |benefit|
      benefit.valid? :submission
    end
  end

  def deductions_complete?
    self.deductions.all? do |deduction|
      deduction.valid? :submission
    end
  end

  def has_income?
    has_job_income || has_self_employment_income || has_other_income
  end


  def delete_embedded_documents_on_driver_qns_update
    if !has_job_income
      incomes.jobs.destroy_all
    end

    if !has_self_employment_income
      incomes.self_employment.destroy_all
    end

    if !has_other_income
      incomes.other.destroy_all
    end

    if !has_enrolled_health_coverage
      benefits.enrolled.destroy_all
    end

    if !has_eligible_health_coverage
      benefits.eligible.destroy_all
    end

    if !has_deductions
      deductions.destroy_all
    end
  end

  def create_embedded_documents_on_driver_qns_update
    if has_job_income
      incomes.find_or_create_by(kind: FinancialAssistance::Income::JOB_INCOME_TYPE_KIND)
    end

    if has_self_employment_income
      incomes.find_or_create_by(kind: FinancialAssistance::Income::NET_SELF_EMPLOYMENT_INCOME_KIND)
    end

    if has_other_income
      incomes.create(kind: nil) if incomes.other.blank?
    end

    if has_enrolled_health_coverage
      benefits.find_or_create_by(kind: "is_enrolled") if benefits.where(kind: "is_enrolled").blank?
    end

    if has_eligible_health_coverage
      benefits.find_or_create_by(kind: "is_eligible") if benefits.where(kind: "is_eligible").blank?
    end

    if has_deductions
      deductions.find_or_create_by(kind: nil) if deductions.blank?
    end
  end

private
  def validate_applicant_information
    validates_presence_of :has_fixed_address, :is_claimed_as_tax_dependent, :is_living_in_state, :is_temp_out_of_state, :family_member_id#, :tax_household_id
  end

  def presence_of_attr_step_1
    if has_job_income.nil?
      errors.add(:has_job_income, "' Does this person have income from an employer?' can't be blank")
    end

    if has_self_employment_income.nil?
      errors.add(:has_self_employment_income, "' Is this person self employed?' can't be blank")
    end

    if has_other_income.nil?
      errors.add(:has_other_income, "' Does this person expect to have other types of income in 2017?' can't be blank")
    end

    if has_deductions.nil?
      errors.add(:has_deductions, "' Does this person expect to have adjustments to income in 2017?' can't be blank")
    end

    if has_enrolled_health_coverage.nil?
      errors.add(:has_enrolled_health_coverage, "' Is this person currently enrolled in health coverage?' can't be blank")
    end

    if has_eligible_health_coverage.nil?
      errors.add(:has_eligible_health_coverage, "' Does this person currently have access to other health coverage, including through another person?' can't be blank")
    end
  end

  def presence_of_attr_step_2
    if is_required_to_file_taxes && is_joint_tax_filing.nil? && has_spouse
      errors.add(:is_joint_tax_filing, "' Will this person be filling jointly?' can't be blank")
    end

    if is_claimed_as_tax_dependent && claimed_as_tax_dependent_by.nil?
      errors.add(:claimed_as_tax_dependent_by, "' This person will be claimed as a dependent by' can't be blank")
    end
  end

  def presence_of_attr_other_qns
    if is_pregnant
      errors.add(:pregnancy_due_on, "' Pregnency Due date' should be answered if you are pregnant") if pregnancy_due_on.nil?
      errors.add(:children_expected_count, "' How many children is this person expecting?' should be answered") if children_expected_count.nil?

      if is_post_partum_period
        errors.add(:is_enrolled_on_medicaid, "' Was this person on Medicaid during pregnency?' should be answered") if is_enrolled_on_medicaid.nil?
      end
    else
      errors.add(:is_post_partum_period, "' Was this person pregnant in the last 60 days?' should be answered") if is_post_partum_period.nil?
      errors.add(:pregnancy_end_on, "' Pregnency End on date' should be answered") if is_post_partum_period.nil?
    end

    if (age_of_applicant > 18 && age_of_applicant < 26)
      if is_former_foster_care.nil?
        errors.add(:is_former_foster_care, "' Was this person in foster care at age 18 or older?' should be answered")
      end

      if is_former_foster_care
        errors.add(:foster_care_us_state, "' Where was this person in foster care?' should be answered") if foster_care_us_state.blank?
        errors.add(:age_left_foster_care, "' How old was this person when they left foster care?' should be answered") if age_left_foster_care.nil?
      end
    end

    if is_student
      errors.add(:student_kind, "' What is the type of student?' should be answered") if student_kind.blank?
      errors.add(:student_status_end_on, "' Student status end on date?'  should be answered") if student_status_end_on.blank?
      errors.add(:student_school_kind, "' What type of school do you go to?' should be answered") if student_school_kind.blank?
    end

    if age_of_applicant.between?(18,19) && is_student.nil?
      errors.add(:is_student, "' Is this person a student?' should be answered")
    end
  end

  def age_of_applicant
    person.age_on(TimeKeeper.date_of_record)
  end

  def clean_params(model_params)
    if model_params[:is_required_to_file_taxes].present? && model_params[:is_required_to_file_taxes] == 'false'
      model_params[:is_joint_tax_filing] = nil
    end

    if model_params[:is_claimed_as_tax_dependent].present? && model_params[:is_claimed_as_tax_dependent] == 'false'
      model_params[:claimed_as_tax_dependent_by] = nil
    end

    # TODO : Revise this logic for conditional saving!
    if model_params[:is_pregnant].present? && model_params[:is_pregnant] == 'false'
      model_params[:pregnancy_due_on] = nil
      model_params[:children_expected_count] = nil
      model_params[:is_enrolled_on_medicaid] = nil if model_params[:is_post_partum_period] == "false"
    end

    if model_params[:is_pregnant].present? && model_params[:is_pregnant] == 'true'
      model_params[:is_post_partum_period] = nil
      model_params[:pregnancy_end_on] = nil
      model_params[:is_enrolled_on_medicaid] = nil
    end

    if model_params[:is_former_foster_care].present? && model_params[:is_former_foster_care] == 'false'
      model_params[:foster_care_us_state] = nil
      model_params[:age_left_foster_care] = nil
      model_params[:had_medicaid_during_foster_care] = nil
    end

    if model_params[:is_student].present? && model_params[:is_student] == 'false'
      model_params[:student_kind] = nil
      model_params[:student_status_end_on] = nil
      model_params[:student_kind] = nil
    end
  end
end
