# frozen_string_literal: true

module FinancialAssistance
  class Applicant # rubocop:disable Metrics/ClassLength TODO: Remove this
    include Mongoid::Document
    include Mongoid::Timestamps
    include AASM
    include Ssn
    include UnsetableSparseFields

    embedded_in :application, class_name: "::FinancialAssistance::Application", inverse_of: :applicants

    TAX_FILER_KINDS = %w[tax_filer single joint separate dependent non_filer].freeze
    STUDENT_KINDS = %w[
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
    ].freeze

    STUDENT_SCHOOL_KINDS = %w[
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
    ].freeze
    INCOME_VALIDATION_STATES = %w[na valid outstanding pending].freeze
    MEC_VALIDATION_STATES = %w[na valid outstanding pending].freeze

    DRIVER_QUESTION_ATTRIBUTES = [:has_job_income, :has_self_employment_income, :has_other_income,
                                  :has_deductions, :has_enrolled_health_coverage, :has_eligible_health_coverage].freeze
    #list of the documents user can provide to verify Immigration status
    VLP_DOCUMENT_KINDS = [
        "I-327 (Reentry Permit)",
        "I-551 (Permanent Resident Card)",
        "I-571 (Refugee Travel Document)",
        "I-766 (Employment Authorization Card)",
        "Certificate of Citizenship",
        "Naturalization Certificate",
        "Machine Readable Immigrant Visa (with Temporary I-551 Language)",
        "Temporary I-551 Stamp (on passport or I-94)",
        "I-94 (Arrival/Departure Record)",
        "I-94 (Arrival/Departure Record) in Unexpired Foreign Passport",
        "Unexpired Foreign Passport",
        "I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)",
        "DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)",
        "Other (With Alien Number)",
        "Other (With I-94 Number)"
    ].freeze

    CITIZEN_KINDS = {
      us_citizen: "US citizen",
      naturalized_citizen: "Naturalized citizen",
      alien_lawfully_present: "Alien lawfully present",
      lawful_permanent_resident: "Lawful permanent resident",
      undocumented_immigrant: "Undocumented immigrant",
      not_lawfully_present_in_us: "Not lawfully present in US",
      non_native_not_lawfully_present_in_us: "Non-native not lawfully present in US",
      ssn_pass_citizenship_fails_with_SSA: "SSN pass citizenship fails with SSA",
      non_native_citizen: "Non-native citizen"
    }.freeze

    NATURALIZATION_DOCUMENT_TYPES = ["Certificate of Citizenship", "Naturalization Certificate"].freeze

    field :name_pfx, type: String
    field :first_name, type: String
    field :middle_name, type: String
    field :last_name, type: String
    field :name_sfx, type: String
    field :encrypted_ssn, type: String
    field :gender, type: String
    field :dob, type: Date

    field :is_primary_applicant, type: Boolean, default: false

    field :is_incarcerated, type: Boolean
    field :is_disabled, type: Boolean
    field :ethnicity, type: Array
    field :race, type: String
    field :indian_tribe_member, type: Boolean
    field :tribal_id, type: String

    field :language_code, type: String
    field :no_dc_address, type: Boolean, default: false
    field :is_homeless, type: Boolean, default: false
    field :is_temporarily_out_of_state, type: Boolean, default: false

    field :no_ssn, type: String, default: '0'
    field :citizen_status, type: String
    field :is_consumer_role, type: Boolean
    field :is_resident_role, type: Boolean
    field :same_with_primary, type: Boolean, default: false
    field :is_applying_coverage, type: Boolean
    field :is_consent_applicant, type: Boolean, default: false
    field :is_tobacco_user, type: String, default: 'unknown'
    field :vlp_document_id, type: String

    field :vlp_subject, type: String
    field :alien_number, type: String
    field :i94_number, type: String
    field :visa_number, type: String
    field :passport_number, type: String
    field :sevis_id, type: String
    field :naturalization_number, type: String
    field :receipt_number, type: String
    field :citizenship_number, type: String
    field :card_number, type: String
    field :country_of_citizenship, type: String
    field :vlp_description, type: String

    # date of expiration of the document. e.g. passport / documentexpiration date
    field :expiration_date, type: DateTime
    # country which issued the document. e.g. passport issuing country
    field :issuing_country, type: String
    # verification type this document can support: Social Security Number, Citizenship, Immigration status, Native American status
    # field :verification_type
    field :is_consent_applicant, type: Boolean, default: false
    field :is_tobacco_user, type: String, default: "unknown"

    field :assisted_income_validation, type: String, default: "pending"
    validates_inclusion_of :assisted_income_validation, :in => INCOME_VALIDATION_STATES, :allow_blank => false
    field :assisted_mec_validation, type: String, default: "pending"
    validates_inclusion_of :assisted_mec_validation, :in => MEC_VALIDATION_STATES, :allow_blank => false
    field :assisted_income_reason, type: String
    field :assisted_mec_reason, type: String

    field :aasm_state, type: String, default: :unverified

    field :person_hbx_id, type: String
    field :family_member_id, type: BSON::ObjectId
    field :eligibility_determination_id, type: BSON::ObjectId

    field :is_active, type: Boolean, default: true

    field :has_fixed_address, type: Boolean, default: true
    field :is_living_in_state, type: Boolean, default: false

    field :is_required_to_file_taxes, type: Boolean
    field :tax_filer_kind, type: String, default: "tax_filer" # change to the response of is_required_to_file_taxes && is_joint_tax_filing
    field :is_joint_tax_filing, type: Boolean
    field :is_claimed_as_tax_dependent, type: Boolean
    field :claimed_as_tax_dependent_by, type: BSON::ObjectId

    field :is_ia_eligible, type: Boolean, default: false
    field :is_physically_disabled, type: Boolean
    field :is_medicaid_chip_eligible, type: Boolean, default: false
    field :is_non_magi_medicaid_eligible, type: Boolean, default: false
    field :is_totally_ineligible, type: Boolean, default: false
    field :is_without_assistance, type: Boolean, default: false
    field :has_income_verification_response, type: Boolean, default: false
    field :has_mec_verification_response, type: Boolean, default: false

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

    embeds_many :verification_types, class_name: "::FinancialAssistance::VerificationType"#, cascade_callbacks: true, validate: true
    embeds_many :incomes,     class_name: "::FinancialAssistance::Income"
    embeds_many :deductions,  class_name: "::FinancialAssistance::Deduction"
    embeds_many :benefits,    class_name: "::FinancialAssistance::Benefit"
    embeds_many :workflow_state_transitions, class_name: "WorkflowStateTransition", as: :transitional
    embeds_many :addresses, cascade_callbacks: true, validate: true, class_name: "::FinancialAssistance::Locations::Address"
    embeds_many :phones, class_name: "::FinancialAssistance::Locations::Phone", cascade_callbacks: true, validate: true
    embeds_many :emails, class_name: "::FinancialAssistance::Locations::Email", cascade_callbacks: true, validate: true
    embeds_one :income_response, class_name: "EventResponse"
    embeds_one :mec_response, class_name: "EventResponse"

    accepts_nested_attributes_for :incomes, :deductions, :benefits
    accepts_nested_attributes_for :phones, :reject_if => proc { |addy| addy[:full_phone_number].blank? }, allow_destroy: true
    accepts_nested_attributes_for :addresses, :reject_if => proc { |addy| addy[:address_1].blank? && addy[:city].blank? && addy[:state].blank? && addy[:zip].blank? }, allow_destroy: true
    accepts_nested_attributes_for :emails, :reject_if => proc { |addy| addy[:address].blank? }, allow_destroy: true

    validate :presence_of_attr_step_1, on: [:step_1, :submission]

    validate :presence_of_attr_other_qns, on: :other_qns
    validate :driver_question_responses, on: :submission
    validates :validate_applicant_information, presence: true, on: :submission

    validate :strictly_boolean

    validates :tax_filer_kind,
              inclusion: { in: TAX_FILER_KINDS, message: "%<value> is not a valid tax filer kind" },
              allow_blank: true

    alias is_medicare_eligible? is_medicare_eligible
    alias is_joint_tax_filing? is_joint_tax_filing

    attr_accessor :relationship
    # attr_writer :us_citizen, :naturalized_citizen, :indian_tribe_member, :eligible_immigration_status

    before_save :generate_hbx_id

    # Responsible for updating family member  when applicant is created/updated
    after_update :propagate_applicant

    def generate_hbx_id
      write_attribute(:person_hbx_id, FinancialAssistance::HbxIdGenerator.generate_member_id) if person_hbx_id.blank?
    end

    def us_citizen=(val)
      @us_citizen = (val.to_s == "true")
      @naturalized_citizen = false if val.to_s == "false"
    end

    def naturalized_citizen=(val)
      @naturalized_citizen = (val.to_s == "true")
    end

    def eligible_immigration_status=(val)
      @eligible_immigration_status = (val.to_s == "true")
    end

    def us_citizen
      return @us_citizen unless @us_citizen.nil?
      return nil if citizen_status.blank?
      @us_citizen ||= ::ConsumerRole::US_CITIZEN_STATUS_KINDS.include?(citizen_status)
    end

    def naturalized_citizen
      return @naturalized_citizen unless @naturalized_citizen.nil?
      return nil if citizen_status.blank?
      @naturalized_citizen ||= (::ConsumerRole::NATURALIZED_CITIZEN_STATUS == citizen_status)
    end

    def eligible_immigration_status
      return @eligible_immigration_status unless @eligible_immigration_status.nil?
      return nil if us_citizen.nil?
      return nil if @us_citizen
      return nil if citizen_status.blank?
      @eligible_immigration_status ||= (::ConsumerRole::ALIEN_LAWFULLY_PRESENT_STATUS == citizen_status)
    end

    def relationships
      application.relationships.in(applicant_id: id)
    end

    def relatives
      relationships.map(&:relative)
    end

    def relationship=(value)
      return if is_primary_applicant?
      application.ensure_relationship_with_primary(self, value)
    end

    def self.encrypt_ssn(val)
      if val.blank?
        return nil
      end
      ssn_val = val.to_s.gsub(/\D/, '')
      SymmetricEncryption.encrypt(ssn_val)
    end

    def relation_with_primary
      return 'self' if is_primary_applicant?

      primary_relationship = relationships.in(relative_id: application.primary_applicant.id).first
      primary_relationship&.kind
    end

    def age_on(date)
      age = date.year - dob.year
      if date.month < dob.month || (date.month == dob.month && date.day < dob.day)
        age - 1
      else
        age
      end
    end

    def is_ia_eligible?
      is_ia_eligible && !is_medicaid_chip_eligible && !is_without_assistance && !is_totally_ineligible
    end

    def non_ia_eligible?
      (is_medicaid_chip_eligible || is_without_assistance || is_totally_ineligible) && !is_ia_eligible
    end

    def is_medicaid_chip_eligible?
      is_medicaid_chip_eligible && !is_ia_eligible && !is_without_assistance && !is_totally_ineligible
    end

    def is_tax_dependent?
      tax_filer_kind.present? && tax_filer_kind == "tax_dependent"
    end

    def strictly_boolean
      errors.add(:base, 'is_ia_eligible should be a boolean') unless is_ia_eligible.is_a?(Boolean)
      errors.add(:base, 'is_medicaid_chip_eligible should be a boolean') unless is_medicaid_chip_eligible.is_a? Boolean
    end

    def tax_filing?
      is_required_to_file_taxes
    end

    def is_claimed_as_tax_dependent?
      is_claimed_as_tax_dependent
    end

    def is_not_in_a_tax_household?
      eligibility_determination.blank?
    end

    aasm do
      state :unverified, initial: true #Both Income and MEC are Pending.
      state :verification_outstanding #Atleast one of the Verifications is Outstanding.
      state :verification_pending #One of the Verifications is Pending and the other Verification is Verified.
      state :fully_verified #Both Income and MEC are Verified.

      event :income_outstanding, :after => [:record_transition, :change_validation_status, :notify_of_eligibility_change] do
        transitions from: :verification_pending, to: :verification_outstanding
        transitions from: :verification_outstanding, to: :verification_outstanding
      end

      event :mec_outstanding, :after => [:record_transition, :change_validation_status, :notify_of_eligibility_change] do
        transitions from: :verification_pending, to: :verification_outstanding
        transitions from: :verification_outstanding, to: :verification_outstanding
      end

      event :income_valid, :after => [:record_transition, :change_validation_status, :notify_of_eligibility_change] do
        transitions from: :verification_pending, to: :verification_pending, unless: :is_mec_verified?
        transitions from: :verification_pending, to: :fully_verified, :guard => :is_mec_verified?
        transitions from: :verification_outstanding, to: :fully_verified, :guard => :is_mec_verified?
        transitions from: :verification_outstanding, to: :verification_outstanding
        transitions from: :fully_verified, to: :fully_verified
      end

      event :mec_valid, :after => [:record_transition, :change_validation_status, :notify_of_eligibility_change] do
        transitions from: :verification_pending, to: :verification_pending, unless: :is_income_verified?
        transitions from: :verification_pending, to: :fully_verified, :guard => :is_income_verified?
        transitions from: :verification_outstanding, to: :fully_verified, :guard => :is_income_verified?
        transitions from: :verification_outstanding, to: :verification_outstanding
        transitions from: :fully_verified, to: :fully_verified
      end

      event :reject, :after => [:record_transition, :notify_of_eligibility_change] do
        transitions from: :unverified, to: :verification_outstanding
        transitions from: :verification_pending, to: :verification_outstanding
        transitions from: :verification_outstanding, to: :verification_outstanding
        transitions from: :fully_verified, to: :verification_outstanding
      end

      event :move_to_pending, :after => [:record_transition, :notify_of_eligibility_change] do
        transitions from: :unverified, to: :verification_pending
        transitions from: :verification_pending, to: :verification_pending
        transitions from: :verification_outstanding, to: :verification_pending
        transitions from: :fully_verified, to: :verification_pending
      end

      event :move_to_unverified, :after => [:record_transition, :notify_of_eligibility_change] do
        transitions from: :unverified, to: :unverified
        transitions from: :verification_pending, to: :unverified
        transitions from: :verification_outstanding, to: :unverified
        transitions from: :fully_verified, to: :unverified
      end
    end

    #Income/MEC
    def valid_mec_response
      update_attributes!(assisted_mec_validation: "valid")
    end

    def invalid_mec_response
      update_attributes!(assisted_mec_validation: "outstanding")
    end

    def valid_income_response
      update_attributes!(assisted_income_validation: "valid")
    end

    def invalid_income_response
      update_attributes!(assisted_income_validation: "outstanding")
    end

    def family
      application.family || family_member.family
    end

    def spouse_relationship
      application.relationships.where(applicant_id: id, kind: 'spouse').first
    end

    def has_spouse
      spouse_relationship.present?
    end

    def eligibility_determination_of_spouse
      return nil unless has_spouse
      spouse_relationship.relative.eligibility_determination
    end

    #### Use Person.consumer_role values for following
    def is_us_citizen?; end

    def is_amerasian?; end

    def is_native_american?; end

    def citizen_status?; end

    def lawfully_present?; end

    def immigration_status?
      person.citizen_status
    end

    def immigration_date?; end

    #### Collect insurance from Benefit model
    def is_enrolled_in_insurance?
      benefits.where(kind: 'is_enrolled').present?
    end

    def is_eligible_for_insurance?
      benefits.where(kind: 'is_eligible').present?
    end

    def had_prior_insurance?; end

    def prior_insurance_end_date; end

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

    def has_i327?
      vlp_subject == "I-327 (Reentry Permit)" && alien_number.present?
    end

    def has_i571?
      vlp_subject == 'I-571 (Refugee Travel Document)' && alien_number.present?
    end

    def has_cert_of_citizenship?
      vlp_subject == "Certificate of Citizenship" && citizenship_number.present?
    end

    def has_cert_of_naturalization?
      vlp_subject == "Naturalization Certificate" && naturalization_number.present?
    end

    def has_temp_i551?
      vlp_subject == "Temporary I-551 Stamp (on passport or I-94)" && alien_number.present?
    end

    def has_i94?
      i94_number.present? && (vlp_subject == "I-94 (Arrival/Departure Record)" || (vlp_subject == "I-94 (Arrival/Departure Record) in Unexpired Foreign Passport" && passport_number.present? && expiration_date.present?))
    end

    def has_i20?
      vlp_subject == "I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)" && sevis_id.present?
    end

    def has_ds2019?
      vlp_subject == "DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)" && sevis_id.present?
    end

    def i551
      vlp_subject == 'I-551 (Permanent Resident Card)' && alien_number.present? && card_number.present?
    end

    def i766
      # vlp_subject == 'I-766 (Employment Authorization Card)' && alien_number.present? && card_number.present? && expiration_date.present?
      vlp_subject == 'I-766 (Employment Authorization Card)' && receipt_number.present? && expiration_.present?
    end

    def mac_read_i551
      vlp_subject == "Machine Readable Immigrant Visa (with Temporary I-551 Language)" && passport_number.present? && alien_number.present?
    end

    def foreign_passport_i94
      vlp_subject == "I-94 (Arrival/Departure Record) in Unexpired Foreign Passport" && i94_number.present? && passport_number.present? && expiration_date.present?
    end

    def foreign_passport
      vlp_subject == "Unexpired Foreign Passport" && passport_number.present? && expiration_date.present?
    end

    def case1
      vlp_subject == "Other (With Alien Number)" && alien_number.present? && vlp_description.present?
    end

    def case2
      vlp_subject == "Other (With I-94 Number)" && i94_number.present? && vlp_description.present?
    end

    def full_name
      @full_name = [name_pfx, first_name, middle_name, last_name, name_sfx].compact.join(" ")
    end

    # Use income entries to determine hours worked
    def total_hours_worked_per_week
      incomes.reduce(0) { |sum_hours, income| sum_hours + income.hours_worked_per_week }
    end

    def tobacco_user
      person.is_tobacco_user || "unknown"
    end


    def eligibility_determination=(eg)
      self.eligibility_determination_id = eg.id
    end

    def eligibility_determination
      return nil unless eligibility_determination_id
      application.eligibility_determinations&.find(eligibility_determination_id)
    end

    def age_on_effective_date
      return @age_on_effective_date unless @age_on_effective_date.blank?
      coverage_start_on = ::Forms::TimeKeeper.new.date_of_record
      return unless coverage_start_on.present?
      age = coverage_start_on.year - dob.year

      # Shave off one year if coverage starts before birthday
      if coverage_start_on.month == dob.month
        age -= 1 if coverage_start_on.day < dob.day
      elsif coverage_start_on.month < dob.month
        age -= 1
      end

      @age_on_effective_date = age
    end

    def contact_addresses
      return addresses if addresses.any? { |address| address.kind == "home" }
      []
    end

    def preferred_eligibility_determination
      eligibility_determination
    end

    def applicant_validation_complete?
      if is_applying_coverage
      valid?(:submission) &&
        incomes.all? {|income| income.valid? :submission} &&
        benefits.all? {|benefit| benefit.valid? :submission} &&
        deductions.all? {|deduction| deduction.valid? :submission} &&
        other_questions_complete?
      else
      valid?(:submission) &&
        incomes.all? {|income| income.valid? :submission} &&
        deductions.all? {|deduction| deduction.valid? :submission} &&
        other_questions_complete?
      end
    end

    def clean_conditional_params(model_params)
      clean_params(model_params)
    end

    def age_of_the_applicant
      age_of_applicant
    end

    def format_citizen
      CITIZEN_KINDS[citizen_status.to_sym]
    end

    def student_age_satisfied?
      [18, 19].include? age_of_applicant
    end

    def foster_age_satisfied?
      # TODO: Look into this. Seems like this is only relevant if pregnant?
      # Age greater than 18 and less than 26
      (19..25).cover? age_of_applicant
    end

    def other_questions_complete?
      questions_array = []

      questions_array << is_former_foster_care  if foster_age_satisfied? && is_applying_coverage
      questions_array << is_post_partum_period  unless is_pregnant

      (other_questions_answers << questions_array).flatten.include?(nil) ? false : true
    end

    def tax_info_complete?
      !is_required_to_file_taxes.nil? &&
        !is_claimed_as_tax_dependent.nil?
    end

    def incomes_complete?
      incomes.all? do |income|
        income.valid? :submission
      end
    end

    def other_incomes_complete?
      incomes.all? do |other_incomes|
        other_incomes.valid? :submission
      end
    end

    def benefits_complete?
      benefits.all? do |benefit|
        benefit.valid? :submission
      end
    end

    def deductions_complete?
      deductions.all? do |deduction|
        deduction.valid? :submission
      end
    end

    def has_income?
      has_job_income || has_self_employment_income || has_other_income
    end

    def embedded_document_section_entry_complete?(embedded_document) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity TODO: Remove this
      case embedded_document
      when :income
        return false if has_job_income.nil? || has_self_employment_income.nil?
        return incomes.jobs.present? && incomes.self_employment.present? if has_job_income && has_self_employment_income
        return incomes.jobs.present? && incomes.self_employment.blank? if has_job_income && !has_self_employment_income
        return incomes.jobs.blank? && incomes.self_employment.present? if !has_job_income && has_self_employment_income
        incomes.jobs.blank? && incomes.self_employment.blank?
      when :other_income
        return false if has_other_income.nil?
        return incomes.other.present? if has_other_income
        incomes.other.blank?
      when :income_adjustment
        return false if has_deductions.nil?
        return deductions.present? if has_deductions
        deductions.blank?
      when :health_coverage
        return false if has_enrolled_health_coverage.nil? || has_eligible_health_coverage.nil?
        return benefits.enrolled.present? && benefits.eligible.present? if has_enrolled_health_coverage && has_eligible_health_coverage
        return benefits.enrolled.present? && benefits.eligible.blank? if has_enrolled_health_coverage && !has_eligible_health_coverage
        return benefits.enrolled.blank? && benefits.eligible.present? if !has_enrolled_health_coverage && has_eligible_health_coverage
        benefits.enrolled.blank? && benefits.eligible.blank?
      end
    end

    def assisted_income_verified?
      assisted_income_validation == "valid"
    end

    def assisted_mec_verified?
      assisted_mec_validation == "valid"
    end

    def admin_verification_action(action, v_type, update_reason)
      if action == "verify"
        update_verification_type(v_type, update_reason)
      elsif action == "return_for_deficiency"
        return_doc_for_deficiency(v_type, update_reason)
      end
    end

    def update_verification_type(v_type, update_reason)
      v_type.update_attributes(validation_status: 'verified', update_reason: update_reason)
      all_types_verified? && !fully_verified? ? verify_ivl_by_admin(v_type) : "#{v_type.type_name} successfully verified."
    end

    def verify_ivl_by_admin(v_type)
      if v_type.type_name == 'Income'
        income_valid!
      else
        mec_valid!
      end
    end

    def all_types_verified?
      verification_types.all?(&:type_verified?)
    end

    def return_doc_for_deficiency(v_type, update_reason)
      v_type.update_attributes(validation_status: 'outstanding', update_reason: update_reason)
      reject!
      "#{v_type.type_name} was rejected"
    end

    def is_assistance_verified?
      !eligible_for_faa? || is_assistance_required_and_verified? ? true : false
    end

    def is_assistance_required_and_verified?
      eligible_for_faa? && income_valid? && mec_valid?
    end

    def income_valid?
      assisted_income_validation == "valid"
    end

    def mec_valid?
      assisted_mec_validation == "valid"
    end

    def eligible_for_faa?
      family.active_approved_application.present?
    end

    def income_pending?
      assisted_doument_pending?("Income")
    end

    def mec_pending?
      assisted_doument_pending?("MEC")
    end

    def income_verification
      verification_types.by_name('Income').first
    end

    def mec_verification
      verification_types.by_name('MEC').first
    end

    def assisted_doument_pending?(kind)
      return true if eligible_for_faa? && verification_types.by_name(kind).present? && verification_types.by_name(kind).first.validation_status == "pending"
      false
    end

    def is_income_verified?
      return true if income_verification.present? && income_verification.validation_status == "verified"
      false
    end

    def is_mec_verified?
      return true if mec_verification.present? && mec_verification.validation_status == 'verified'
      false
    end

    def job_income_exists?
      incomes.jobs.present?
    end

    def self_employment_income_exists?
      incomes.self_employment.present?
    end

    def other_income_exists?
      incomes.other.present?
    end

    def deductions_exists?
      deductions.present?
    end

    def enrolled_health_coverage_exists?
      benefits.enrolled.present?
    end

    def eligible_health_coverage_exists?
      benefits.eligible.present?
    end

    def attributes_for_export
      applicant_params = attributes.transform_keys(&:to_sym).slice(:family_member_id,:person_hbx_id,:name_pfx,:first_name,:middle_name,:last_name,:name_sfx,
                                          :gender,:is_incarcerated,:is_disabled,:ethnicity,:race,:tribal_id,:language_code,:no_dc_address,:is_homeless,
                                          :is_temporarily_out_of_state,:no_ssn,:citizen_status,:is_consumer_role,:vlp_document_id,:is_applying_coverage,
                                          :vlp_subject,:alien_number,:i94_number,:visa_number,:passport_number,:sevis_id,:naturalization_number,
                                          :receipt_number,:citizenship_number,:card_number,:country_of_citizenship, :issuing_country,:status,
                                          :indian_tribe_member, :same_with_primary,:vlp_description)
      applicant_params.merge!({dob: dob.strftime('%d/%m/%Y'), ssn: ssn, relationship: relation_with_primary})
      applicant_params.merge!(expiration_date: expiration_date.strftime('%d/%m/%Y')) if expiration_date.present?
      applicant_params[:addresses] = construct_association_fields(addresses)
      applicant_params[:emails] = construct_association_fields(emails)
      applicant_params[:phones] = construct_association_fields(phones)
      applicant_params
    end

    def construct_association_fields(records)
      records.collect{|record| record.attributes.except(:_id, :created_at, :updated_at) }
    end

    class << self
      def find(id)
        return nil unless id
        bson_id = BSON::ObjectId.from_string(id.to_s)
        applications = ::FinancialAssistance::Application.where("applicants._id" => bson_id)
        applications.size == 1 ? applications.first.applicants.find(bson_id) : nil
      end
    end

    private

    def change_validation_status
      kind = aasm.current_event.to_s.include?('income') ? 'Income' : 'MEC'
      status = aasm.current_event.to_s.include?('outstanding') ? 'outstanding' : 'verified'
      verification_types.by_name(kind).first.update_attributes!(validation_status: status)
    end

    def other_questions_answers
      return [] unless is_applying_coverage
      [:has_daily_living_help, :need_help_paying_bills, :is_ssn_applied].inject([]) do |array, question|
        no_ssn_flag = no_ssn

        array << send(question) if question != :is_ssn_applied || (question == :is_ssn_applied && no_ssn_flag == '1')
        array
      end
    end

    def validate_applicant_information
      if is_applying_coverage
        validates_presence_of :has_fixed_address, :is_claimed_as_tax_dependent, :is_living_in_state, :is_temporarily_out_of_state, :is_pregnant, :is_self_attested_blind, :has_daily_living_help, :need_help_paying_bills #, :tax_household_id
      else
        validates_presence_of :has_fixed_address, :is_claimed_as_tax_dependent, :is_living_in_state, :is_temporarily_out_of_state, :is_pregnant
      end
    end

    def driver_question_responses
      DRIVER_QUESTION_ATTRIBUTES.each do |attribute|
        next if [:has_enrolled_health_coverage, :has_eligible_health_coverage].include?(attribute) && !is_applying_coverage

        instance_type = attribute.to_s.gsub('has_', '')
        instance_check_method = instance_type + "_exists?"

        # Add error to attribute that has a nil value.
        errors.add(attribute, "#{attribute.to_s.titleize} can not be a nil") if send(attribute).nil?

        # Add base error when driver question has a 'Yes' value and there is No existing instance for that type.
        if send(attribute) && !public_send(instance_check_method)
          errors.add(:base, "Based on your response, you should have at least one #{instance_type.titleize}.
                             Please correct your response to '#{attribute}', or add #{instance_type.titleize}.")
        end

        # Add base error when driver question has a 'No' value and there is an existing instance for that type.
        if !send(attribute) && public_send(instance_check_method)
          errors.add(:base, "Based on your response, you should have no instance of #{instance_type.titleize}.
                             Please correct your response to '#{attribute}', or delete the existing #{instance_type.titleize}.")
        end
      end
    end

    def presence_of_attr_step_1
      errors.add(:is_joint_tax_filing, "' Will this person be filling jointly?' can't be blank") if is_required_to_file_taxes && is_joint_tax_filing.nil? && has_spouse

      errors.add(:claimed_as_tax_dependent_by, "' This person will be claimed as a dependent by' can't be blank") if is_claimed_as_tax_dependent && claimed_as_tax_dependent_by.nil?

      errors.add(:is_required_to_file_taxes, "' is_required_to_file_taxes can't be blank") if is_required_to_file_taxes.nil?

      errors.add(:is_claimed_as_tax_dependent, "' is_claimed_as_tax_dependent can't be blank") if is_claimed_as_tax_dependent.nil?
    end

    def presence_of_attr_other_qns # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity TODO: Remove this
      return true
      if is_pregnant
        errors.add(:pregnancy_due_on, "' Pregnancy Due date' should be answered if you are pregnant") if pregnancy_due_on.blank?
        errors.add(:children_expected_count, "' How many children is this person expecting?' should be answered") if children_expected_count.blank?
      # Nil or "" means unanswered, true/or false boolean will be passed through
      elsif is_post_partum_period.nil? || is_post_partum_period == ""
        # Even if they aren't pregnant, still need to ask if they were pregnant within the last 60 days
        errors.add(:is_post_partum_period, "' Was this person pregnant in the last 60 days?' should be answered")
      end
      # If they're in post partum period, they need to tell us if they were on medicaid and when the pregnancy ended
      if is_post_partum_period.present?
        # Enrolled on medicaid must check if nil
        errors.add(:is_enrolled_on_medicaid, "' Was this person on Medicaid during pregnancy?' should be answered") if is_enrolled_on_medicaid.nil?
        errors.add(:pregnancy_end_on, "' Pregnancy End on date' should be answered") if pregnancy_end_on.blank?
      end

      return unless is_applying_coverage

      if age_of_applicant > 18 && age_of_applicant < 26
        errors.add(:is_former_foster_care, "' Was this person in foster care at age 18 or older?' should be answered") if is_former_foster_care.nil?

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

      errors.add(:is_student, "' Is this person a student?' should be answered") if age_of_applicant.between?(18,19) && is_student.nil?
      # TODO: Decide if these validations should be ended?
      # errors.add(:claimed_as_tax_dependent_by, "' This person will be claimed as a dependent by' can't be blank") if is_claimed_as_tax_dependent && claimed_as_tax_dependent_by.nil?

      # errors.add(:is_required_to_file_taxes, "' is_required_to_file_taxes can't be blank") if is_required_to_file_taxes.nil?
    end

    def age_of_applicant
      age_on(TimeKeeper.date_of_record)
    end

    def clean_params(model_params) # rubocop:disable Metrics/CyclomaticComplexity TODO: Remove this
      model_params[:is_joint_tax_filing] = nil if model_params[:is_required_to_file_taxes].present? && model_params[:is_required_to_file_taxes] == 'false'

      model_params[:claimed_as_tax_dependent_by] = nil if model_params[:is_claimed_as_tax_dependent].present? && model_params[:is_claimed_as_tax_dependent] == 'false'

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

      return unless model_params[:is_student].present? && model_params[:is_student] == 'false'
      model_params[:student_kind] = nil
      model_params[:student_status_end_on] = nil
      model_params[:student_kind] = nil
    end

    def record_transition
      workflow_state_transitions << WorkflowStateTransition.new(
        from_state: aasm.from_state,
        to_state: aasm.to_state,
        event: aasm.current_event,
        user_id: SAVEUSER[:current_user_id]
      )
    end

    #Income/MEC Verifications
    def notify_of_eligibility_change
      # CoverageHousehold.update_eligibility_for_family(family)
    end

    def propagate_applicant
      # return if incomes_changed? || benefits_changed? || deductions_changed?
      if is_active
        Operations::Families::CreateOrUpdateMember.new.call(params: {applicant_params: self.attributes_for_export, family_id: application.family_id})
        if create_or_update_result.success?
          response_family_member_id = create_or_update_result.success[:family_member_id]
          update_attributes!(family_member_id: response_family_member_id) if family_member_id.nil?
        end
      end

      Operations::Families::DropMember.new.call(params: {family_id: application.family_id, family_member_id: family_member_id}) if is_active_changed? && is_active == false
    rescue StandardError => e
      e.message
    end
  end
end
