class FinancialAssistance::Application

  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM
  include Acapi::Notifiers
  include Concerns::Observable
  include ModelEvents::FaaApplication
  require 'securerandom'

  belongs_to :family, class_name: "::Family"

  before_create :set_hbx_id, :set_applicant_kind, :set_request_kind, :set_motivation_kind, :set_us_state, :set_is_ridp_verified, :set_benchmark_plan_id, :set_external_identifiers
  validates :application_submission_validity, presence: true, on: :submission
  validates :before_attestation_validity, presence: true, on: :before_attestation
  validate :attestation_terms_on_parent_living_out_of_home

  YEARS_TO_RENEW_RANGE = 0..5
  RENEWAL_BASE_YEAR_RANGE = 2013..TimeKeeper.date_of_record.year + 1

  APPLICANT_KINDS   = ["user and/or family", "call center rep or case worker", "authorized representative"]
  SOURCE_KINDS      = %w(paper source in-person)
  REQUEST_KINDS     = %w()
  MOTIVATION_KINDS  = %w(insurance_affordability)

  SUBMITTED_STATUS  = %w(submitted verifying_income)

  FAA_SCHEMA_FILE_PATH     = File.join(Rails.root, 'lib', 'schemas', 'financial_assistance.xsd')

  # TODO: Need enterprise ID assignment call for Assisted Application
  field :hbx_id, type: String

  ## Remove after data Cleanup ##
  field :external_id, type: String
  field :integrated_case_id, type: String
  ##

  field :haven_app_id, type: String
  field :haven_ic_id, type: String
  field :e_case_id, type: String

  field :applicant_kind, type: String

  field :request_kind, type: String
  field :motivation_kind, type: String

  field :is_joint_tax_filing, type: Boolean
  field :eligibility_determination_id, type: BSON::ObjectId

  field :aasm_state, type: String, default: :draft
  field :submitted_at, type: DateTime
  field :effective_date, type: DateTime # Date they want coverage
  field :timeout_response_last_submitted_at, type: DateTime

  # The `assistance_year` of an application gets set during the submission of an application.
  # Use `application_applicable_year` method in the Family model incase you need `assistance_year`
  # when aplication is in a `draft state`.
  field :assistance_year, type: Integer

  field :is_renewal_authorized, type: Boolean, default: true
  field :renewal_base_year, type: Integer
  field :years_to_renew, type: Integer

  field :is_requesting_voter_registration_application_in_mail, type: Boolean

  field :us_state, type: String
  field :benchmark_plan_id, type: BSON::ObjectId

  field :medicaid_terms, type: Boolean
  field :medicaid_insurance_collection_terms, type: Boolean
  field :report_change_terms, type: Boolean
  field :parent_living_out_of_home_terms, type: Boolean
  field :attestation_terms, type: Boolean
  field :submission_terms, type: Boolean

  field :request_full_determination, type: Boolean

  field :is_ridp_verified, type: Boolean
  field :determination_http_status_code, type: Integer
  field :determination_error_message, type: String
  field :has_eligibility_response, type: Boolean, default: false

  field :workflow, type: Hash, default: { }

  embeds_many :applicants, class_name: "::FinancialAssistance::Applicant"

  embeds_many :workflow_state_transitions, as: :transitional

  accepts_nested_attributes_for :applicants, :workflow_state_transitions

  # validates_presence_of :hbx_id, :applicant_kind, :request_kind, :benchmark_plan_id

  # User must agree with terms of service check boxes
  # validates_acceptance_of :medicaid_terms, :attestation_terms, :submission_terms

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

  after_save :notify_on_save

  scope :submitted, ->{ any_in(aasm_state: SUBMITTED_STATUS) }
  scope :determined, ->{ any_in(aasm_state: "determined") }
  scope :by_hbx_id, ->(hbx_id) { where(hbx_id: hbx_id) }

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
    @primary_applicant = active_applicants.detect { |applicant| applicant.is_primary_applicant? }
  end


  # TODO: define the states and transitions for Assisted Application workflow process
  aasm do
    state :draft, initial: true
    state :submitted
    state :determination_response_error
    state :determined

    event :submit, :after => :record_transition do
      transitions from: :draft, to: :submitted, :after => :set_submit do
        guard do
          is_application_valid?
        end
      end

      transitions from: :draft, to: :draft, :after => :report_invalid do
        guard do
          not is_application_valid?
        end
      end
    end

    event :unsubmit, :after => :record_transition do
      transitions from: :submitted, to: :draft, :after => :unset_submit do
        guard do
          true # add appropriate guard here
        end
      end
    end

    event :set_determination_response_error, :after => :record_transition do
      transitions from: :submitted, to: :determination_response_error
    end

    event :determine, :after => :record_transition do
      transitions from: :submitted, to: :determined, :after => [:verification_update_for_applicants]
    end

  end

  # def applicant
  #   return nil unless tax_household_member
  #   tax_household_member.family_member
  # end

  # The following methods will need to be refactored as there are multiple eligibility determinations - per THH
  # def eligibility_determination=(ed_instance)
  #   return unless ed_instance.is_a? EligibilityDetermination
  #   self.eligibility_determination_id = ed_instance._id
  #   @eligibility_determination = ed_instance
  # end

  # def eligibility_determination
  #   return nil unless tax_household_member
  #   return @eligibility_determination if defined? @eligibility_determination
  #   @eligibility_determination = tax_household_member.eligibility_determinations.detect { |elig_d| elig_d._id == self.eligibility_determination_id }
  # end

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

  def is_family_totally_ineligibile
    active_applicants.each { |applicant| return false unless applicant.is_totally_ineligible }
    return true
  end

  def active_determined_tax_households
    tax_households.where(is_eligibility_determined: true)
  end

  def tax_households
    family.active_household.tax_households.where(application_id: id.to_s)
  end

  def eligibility_determinations
    tax_households.inject([]) do |ed, th|
      ed << th.eligibility_determinations
      ed.flatten
    end
  end

  def populate_applicants_for(family)
    self.applicants = family.active_family_members.map do |family_member|
      FinancialAssistance::Applicant.new family_member_id: family_member.id
    end
  end

  def current_csr_eligibility_kind(tax_household_id)
    eligibility_determination = eligibility_determination_for_tax_household(tax_household_id)
    eligibility_determination.present? ? eligibility_determination.csr_eligibility_kind : "csr_100"
  end

  def eligibility_determination_for_tax_household(tax_household_id)
    family.active_household.tax_households.where(id: tax_household_id).first.preferred_eligibility_determination
  end

  def tax_household_for_family_member(family_member_id)
    tax_households.where(is_eligibility_determined: true).select {|th| th if th.active_applicants.where(family_member_id: family_member_id).present? }.first
  end

  def latest_active_tax_households_with_year(year)
    tax_households = active_determined_tax_households.tax_household_with_year(year)
    if TimeKeeper.date_of_record.year == year
      tax_households = active_determined_tax_households.tax_household_with_year(year).active_tax_household
    end
    tax_households
  end

  def eligibility_determinations_for_year(year)
    return nil unless self.assistance_year == year
    self.eligibility_determinations
  end

  def complete?
    is_application_valid? # && check for the validity of applicants too.
  end

  def is_schema_valid?(faa_doc)
    return false if faa_doc.blank?
    faa_xsd = Nokogiri::XML::Schema(File.open FAA_SCHEMA_FILE_PATH)
    faa_xsd.valid?(faa_doc)
  end

  def is_submitted?
    self.aasm_state == "submitted"
  end

  def publish(payload)
    #return true #For DEMO purpose only #temporary
    if validity = self.is_schema_valid?(Nokogiri::XML.parse(payload))
      notify("acapi.info.events.assistance_application.submitted",
                {:correlation_id => SecureRandom.uuid.gsub("-",""),
                  :body => payload,
                  :family_id => self.family_id.to_s,
                  :assistance_application_id => self.hbx_id.to_s})
    else
      false
    end
    validity
  end

  def send_failed_response
    if !has_eligibility_response
      message = "Timed-out waiting for eligibility determination response"
      return_status = 504
      notify("acapi.info.events.eligibility_determination.rejected",
          {:correlation_id => SecureRandom.uuid.gsub("-",""),
            :body => { error_message: message },
            :family_id => family_id.to_s,
            :assistance_application_id => _id.to_s,
            :return_status => return_status.to_s,
            :submitted_timestamp => TimeKeeper.date_of_record.strftime('%Y-%m-%dT%H:%M:%S')})
    end

    if has_eligibility_response && determination_http_status_code == 422 && determination_error_message == "Failed to validate Eligibility Determination response XML"
      message = "Invalid schema eligibility determination response provided"
      notify("acapi.info.events.eligibility_determination.rejected",
          {:correlation_id => SecureRandom.uuid.gsub("-",""),
            :body => { error_message: message },
            :family_id => family_id.to_s,
            :assistance_application_id => _id.to_s,
            :return_status => determination_http_status_code.to_s,
            :submitted_timestamp => TimeKeeper.date_of_record.strftime('%Y-%m-%dT%H:%M:%S'),
            :haven_application_id => haven_app_id,
            :haven_ic_id => haven_ic_id,
            :primary_applicant_id => family.primary_applicant.person.hbx_id.to_s })
    end
  end

  def ready_for_attestation?
    application_valid = is_application_ready_for_attestation?
    # && chec.k for the validity of all applicants too.
    self.active_applicants.each do |applicant|
      return false unless applicant.applicant_validation_complete?
    end
    application_valid && family.relationships_complete?
  end

  def is_draft?
    self.aasm_state == "draft" ? true : false
  end

  def is_determined?
    self.aasm_state == "determined" ? true : false
  end

  def incomplete_applicants?
    active_applicants.each do |applicant|
      return true if applicant.applicant_validation_complete? == false
    end
    return false
  end

  def next_incomplete_applicant
    active_applicants.each do |applicant|
      return applicant if applicant.applicant_validation_complete? == false
    end
  end

  def active_applicants
    applicants.where(:is_active => true)
  end

  def clean_conditional_params(model_params)
    clean_params(model_params)
  end

  def success_status_codes?(payload_http_status_code)
    [200, 203].include?(payload_http_status_code)
  end

  def check_verification_response
    if !has_all_uqhp_applicants? && !has_atleast_one_medicaid_applicant? && !has_all_verified_applicants? && (TimeKeeper.datetime_of_record.prev_day > submitted_at)
      if timeout_response_last_submitted_at.blank? || (timeout_response_last_submitted_at.present? && (TimeKeeper.datetime_of_record.prev_day > timeout_response_last_submitted_at))
         self.update_attributes(timeout_response_last_submitted_at: TimeKeeper.datetime_of_record)
        active_applicants.each do |applicant|
          if !applicant.has_income_verification_response && !applicant.has_mec_verification_response
            type = "Income, MEC"
          elsif applicant.has_income_verification_response && !applicant.has_mec_verification_response
            type = "MEC"
          else
            type = "Income" if (!applicant.has_income_verification_response && applicant.has_mec_verification_response)
          end
          notify("acapi.info.events.verification.rejected",
            { :correlation_id => SecureRandom.uuid.gsub("-",""),
              :body => JSON.dump({
                error: "Timed-out waiting for verification response",
                applicant_first_name: applicant.person.first_name,
                applicant_last_name: applicant.person.last_name,
                applicant_id: applicant.person.hbx_id,
                rejected_verification_types: type}),
              :assistance_application_id => self._id.to_s,
              :family_id => self.family_id.to_s,
              :haven_application_id => haven_app_id,
              :haven_ic_id => haven_ic_id,
              :reject_status => 504,
              :submitted_timestamp => TimeKeeper.datetime_of_record.strftime('%Y-%m-%dT%H:%M:%S')
            }
          )
        end
      end
    end
  end

  def has_all_verified_applicants?
    !active_applicants.map(&:has_income_verification_response).include?(false) && !active_applicants.map(&:has_mec_verification_response).include?(false)
  end

  def has_atleast_one_medicaid_applicant?
    active_applicants.map(&:is_medicaid_chip_eligible).include?(true)
  end

  def has_all_uqhp_applicants?
    !active_applicants.map(&:is_without_assistance).include?(false)
  end

  def has_atleast_one_assisted_but_no_medicaid_applicant?
    active_applicants.map(&:is_ia_eligible).include?(true) && !active_applicants.map(&:is_medicaid_chip_eligible).include?(true)
  end

  def copy_application
    if self.family.application_in_progress.blank?
      self.applicants.each do |applicant|
        applicant.person.person_relationships.each do |pr|
          puts pr.inspect
        end
      end
      new_application = self.dup
      new_application.applicants.each do |applicant|
        applicant.person.person_relationships.each do |pr|
          puts pr.inspect
        end
      end
      new_application.aasm_state = "draft"
      new_application.submitted_at = nil
      new_application.created_at = nil
      new_application.hbx_id = HbxIdGenerator.generate_application_id
      new_application.determination_http_status_code = nil
      new_application.determination_error_message = nil
      new_application.save!
      new_application.sync_family_members_with_applicants
      new_application
    end
  end

  def sync_family_members_with_applicants
    active_member_ids = family.active_family_members.map(&:id)
    applicants.each do |app| app.update_attributes(:is_active => false) if !active_member_ids.include?(app.family_member_id) end
    active_applicant_family_member_ids = active_applicants.map(&:family_member_id)
    family.active_family_members.each do |fm|
      if !active_applicant_family_member_ids.include?(fm.id)
        applicant_in_context = applicants.where(family_member_id: fm.id)
        if applicant_in_context.present?
          applicant_in_context.first.update_attributes(is_active: true)
        else
          applicants.create(family_member_id: fm.id)
        end
      end
    end
  end

private

  def clean_params(model_params)
    model_params[:attestation_terms] = nil if model_params[:parent_living_out_of_home_terms].present? && model_params[:parent_living_out_of_home_terms] == 'false'
    model_params[:years_to_renew] = "5" if model_params[:is_renewal_authorized].present? && model_params[:is_renewal_authorized] == "true"
  end

  def attestation_terms_on_parent_living_out_of_home
    if parent_living_out_of_home_terms
      errors.add(:attestation_terms, "can't be blank") if attestation_terms.nil?
    end
  end

  def trigger_eligibilility_notice
    if is_family_totally_ineligibile
      IvlNoticesNotifierJob.perform_later(self.primary_applicant.person.id.to_s, "ineligibility_notice")
    else
      IvlNoticesNotifierJob.perform_later(self.primary_applicant.person.id.to_s, "eligibility_notice")
    end
  end

  def set_hbx_id
    #TODO: Use hbx_id generator for Application
    write_attribute(:hbx_id, HbxIdGenerator.generate_application_id) if hbx_id.blank?
  end

  def set_applicant_kind
    #TODO: Implement logic to handle "call center rep or case worker", "authorized representative"
    write_attribute(:applicant_kind, "user and/or family")
  end

  def set_request_kind
    #TODO: Populate correct request kind
    write_attribute(:request_kind, "placeholder")
  end

  def set_motivation_kind
    #TODO: Populate correct motivation kind
    write_attribute(:motivation_kind, "insurance_affordability")
  end

  def set_is_ridp_verified
    #TODO: Rewrite to populate RIDP result?
    write_attribute(:is_ridp_verified, true)
  end

  def set_us_state
    write_attribute(:us_state, HbxProfile::StateAbbreviation)
  end

  def set_submission_date
    update_attribute(:submitted_at, Time.current)
  end

  def set_assistance_year
    assistance_year = self.family.application_applicable_year
    update_attribute(:assistance_year, assistance_year)
  end

  def set_effective_date
    effective_date = HbxProfile.try(:current_hbx).try(:benefit_sponsorship).try(:earliest_effective_date)
    update_attribute(:effective_date, effective_date)
  end

  def set_benchmark_plan_id
    benchmark_plan_id = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.slcsp
    write_attribute(:benchmark_plan_id, benchmark_plan_id)
  end

  def set_external_identifiers
    app  = family.active_approved_application
    if app.present?
      write_attribute(:haven_app_id, app.haven_app_id)
      write_attribute(:haven_ic_id, app.haven_ic_id)
      write_attribute(:e_case_id, app.e_case_id)
    end
  end

  def unset_submission_date
    update_attribute(:submitted_at, nil)
  end

  def unset_assistance_year
    update_attribute(:assistance_year, nil)
  end

  def unset_effective_date
    update_attribute(:effective_date, nil)
  end

  def application_submission_validity
    # Mandatory Fields before submission
    validates_presence_of :hbx_id, :applicant_kind, :request_kind, :motivation_kind, :us_state, :is_ridp_verified, :parent_living_out_of_home_terms
    # User must agree with terms of service check boxes before submission
    validates_acceptance_of :medicaid_terms, :submission_terms, :medicaid_insurance_collection_terms, :report_change_terms, accept: true
  end

  def before_attestation_validity
    validates_presence_of :hbx_id, :applicant_kind, :request_kind, :motivation_kind, :us_state, :is_ridp_verified
  end

  def is_application_valid?
    application_attributes_validity = self.valid?(:submission) ? true : false

    if family.relationships_complete?
      relationships_validity = true
    else
      self.errors[:base] << "You must have a complete set of relationships defined among every member."
      relationships_validity = false
    end

    application_attributes_validity && relationships_validity
  end

  def is_application_ready_for_attestation?
    self.valid?(:before_attestation) ? true : false
  end

  def report_invalid
    #TODO: Invalid Report here
  end

  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state
    )
  end

  def verification_update_for_applicants
    if aasm_state == "determined"
      if has_atleast_one_medicaid_applicant?
        update_verifications_of_applicants("external_source")
      elsif has_all_uqhp_applicants?
        update_verifications_of_applicants("not_required")
      elsif has_atleast_one_assisted_but_no_medicaid_applicant?
        update_verifications_of_applicants("pending")
      end
    end
  end

  def update_verifications_of_applicants(status)
    active_applicants.each do |applicant|
      applicant.assisted_verifications.each { |verification| verification.update_attributes(status: status) }
    end
  end

  def set_submit
    set_submission_date
    set_assistance_year
    set_effective_date
    create_tax_households
    create_verification_documents
  end

  def unset_submit
    unset_submission_date
    unset_assistance_year
    unset_effective_date
    delete_tax_households
    delete_verification_documents
  end

  def create_tax_households
    ## Remove  when copy method is fixed to exclude copying Tax Household
    active_applicants.each { |applicant| applicant.update_attributes!(tax_household_id: nil)  }

    non_tax_dependents = active_applicants.where(is_claimed_as_tax_dependent: false)
    tax_dependents= active_applicants.where(is_claimed_as_tax_dependent: true)

    non_tax_dependents.each do |applicant|
      if applicant.is_joint_tax_filing? && applicant.is_not_in_a_tax_household? && applicant.tax_household_of_spouse.present?
        # Assign joint filer to THH of Spouse.
        applicant.tax_household = applicant.tax_household_of_spouse
        applicant.update_attributes!(tax_filer_kind: 'tax_filer')
      else
        # Create a new THH and assign it to the applicant
        # Need THH for Medicaid cases too
        applicant.tax_household = family.active_household.tax_households.create!(application_id: id)
        applicant.update_attributes!(tax_filer_kind: applicant.tax_filing? ? 'tax_filer' : 'non_filer')
      end
    end

    tax_dependents.each do |applicant|
      # Assign applicant to the same THH that the person claiming this dependent belongs to.
      thh_of_claimer = non_tax_dependents.find(applicant.claimed_as_tax_dependent_by).tax_household
      applicant.tax_household = thh_of_claimer if thh_of_claimer.present?
      applicant.update_attributes!(tax_filer_kind: 'dependent')
    end

    # delete THH without any applicant.
    empty_th = tax_households.select do |th|
      active_applicants.map(&:tax_household).exclude?(th)
    end
    empty_th.each &:destroy
  end

  def delete_tax_households
    tax_households.destroy_all
  end

  def create_verification_documents
    applicants.each do |applicant|
      income_assisted_verification = applicant.assisted_verifications.create!(status: "submitted", verification_type: "Income")
      mec_assisted_verification = applicant.assisted_verifications.create!(status: "submitted", verification_type: "MEC")
    end
  end

  def delete_verification_documents
    applicants.each do |applicant|
      applicant.assisted_verifications.destroy_all
    end
  end
end
