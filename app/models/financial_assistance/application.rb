class FinancialAssistance::Application

  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM
  include Acapi::Notifiers
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

  embeds_many :tax_households, class_name: "::TaxHousehold"
  embeds_many :applicants, class_name: "::FinancialAssistance::Applicant"
  embeds_many :eligibility_determinations, class_name: "::EligibilityDetermination"
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
      transitions from: :submitted, to: :determined, :after => :trigger_eligibilility_notice
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

  def all_tax_households
    tax_households = []
    active_applicants.each do |applicant|
       tax_households << applicant.tax_household
    end
    tax_households.uniq
  end

  def populate_applicants_for(family)
    self.applicants = family.family_members.map do |family_member|
      FinancialAssistance::Applicant.new family_member_id: family_member.id
    end
  end

  def current_csr_eligibility_kind(tax_household_id)
    eligibility_determination = eligibility_determination_for_tax_household(tax_household_id)
    eligibility_determination.present? ? eligibility_determination.csr_eligibility_kind : "csr_100"
  end

  def eligibility_determination_for_tax_household(tax_household_id)
    eligibility_determinations.where(tax_household_id: tax_household_id).first
  end

  def tax_household_for_family_member(family_member_id)
    tax_households.select {|th| th if th.active_applicants.where(family_member_id: family_member_id).present? }.first
  end

  # TODO: Move to Aplication model and refactor accordingly.
  def latest_active_tax_households_with_year(year)
    tax_households = self.tax_households.tax_household_with_year(year)
    if TimeKeeper.date_of_record.year == year
      tax_households = self.tax_households.tax_household_with_year(year).active_tax_household
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
    if validity = self.is_schema_valid?(Nokogiri::XML.parse(payload))
      notify("acapi.info.events.assistance_application.submitted",
                {:correlation_id => SecureRandom.uuid.gsub("-",""),
                  :body => payload,
                  :family_id => self.family_id.to_s,
                  :assistance_application_id => self._id.to_s})
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

    if has_eligibility_response && determination_http_status_code == 422
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

  def build_or_update_tax_households_and_applicants_and_eligibility_determinations(verified_family, primary_person, active_verified_household)
    verified_primary_family_member = verified_family.family_members.detect{ |fm| fm.person.hbx_id == verified_family.primary_family_member_id }
    verified_tax_households = active_verified_household.tax_households.select{|th| th.primary_applicant_id == verified_family.primary_family_member_id}
    #Saving EDs only if all the tax_households get the EDs from Haven
    if verified_tax_households.present?# && !verified_tax_households.map(&:eligibility_determinations).map(&:present?).include?(false)

      # verified_primary_tax_household_member = verified_tax_household.tax_household_members.select{|thm| thm.id == verified_primary_family_member.id }.first
      # primary_family_member = self.family_members.select{|p| primary_person == p.person}.first

      # if tax_households.present?
        # latest_tax_household = tax_households.where(effective_ending_on: nil).last
        # latest_tax_household.update_attributes(effective_ending_on: verified_tax_household.start_date)
      # end
      tax_households_hbx_assigned_ids = []
      tax_households.each { |th| tax_households_hbx_assigned_ids << th.hbx_assigned_id.to_s}
      benchmark_plan_id = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.slcsp
      verified_tax_households.each do |vthh|
        #If taxhousehold exists in our DB
        if tax_households_hbx_assigned_ids.include?(vthh.hbx_assigned_id)
          tax_household = tax_households.where(hbx_assigned_id: vthh.hbx_assigned_id).first
          #Update required attributes for that particular TaxHouseHold
          tax_household.update_attributes(effective_starting_on: vthh.start_date)

          #Applicant/TaxHouseholdMember block start
          applicants_persons_hbx_ids = []
          active_applicants.each { |appl| applicants_persons_hbx_ids << appl.person.hbx_id.to_s}
          vthh.tax_household_members.each do |thhm|
            #If applicant exisits in our db.
            if applicants_persons_hbx_ids.include?(thhm.person_id)
              applicant = active_applicants.select { |applicant| active_applicants.person.hbx_id == thhm.person_id }.first

              # verified_family_member = verified_family.family_members.detect { |vfm| vfm.person.id == thhm.person_id }
              # applicant.update_attributes({is_without_assistance: verified_family_member.is_without_assistance, is_ia_eligible: verified_family_member.is_insurance_assistance_eligible, is_medicaid_chip_eligible: verified_family_member.is_medicaid_chip_eligible, is_non_magi_medicaid_eligible: verified_family_member.is_non_magi_medicaid_eligible, is_totally_ineligible: verified_family_member.is_totally_ineligible})
              #Updating the applicant by finding the right family member.
              verified_family.family_members.each do |verified_family_member|
                if verified_family_member.person.hbx_id == thhm.person_id
                  applicant.update_attributes({
                    medicaid_household_size: verified_family_member.medicaid_household_size,
                    magi_medicaid_category: verified_family_member.magi_medicaid_category,
                    magi_as_percentage_of_fpl: verified_family_member.magi_as_percentage_of_fpl,
                    magi_medicaid_monthly_income_limit: verified_family_member.magi_medicaid_monthly_income_limit,
                    magi_medicaid_monthly_household_income: verified_family_member.magi_medicaid_monthly_household_income,
                    is_without_assistance: verified_family_member.is_without_assistance,
                    is_ia_eligible: verified_family_member.is_insurance_assistance_eligible,
                    is_medicaid_chip_eligible: verified_family_member.is_medicaid_chip_eligible,
                    is_non_magi_medicaid_eligible: verified_family_member.is_non_magi_medicaid_eligible,
                    is_totally_ineligible: verified_family_member.is_totally_ineligible})
                end
              end
            end
          end
          #Applicant/TaxHouseholdMember block end

          #Eligibility determination start.
          if !verified_tax_households.map(&:eligibility_determinations).map(&:present?).include?(false)
            verified_eligibility_determination = vthh.eligibility_determinations.max_by(&:determination_date) #Finding the right Eligilbilty Determination

            #TODO find the right source Curam/Haven.
            source = "Haven"
            create_new_eligibility_determination(tax_household.id, verified_eligibility_determination, benchmark_plan_id, source) #Creating Eligibility Determination
          end
          #Eligibility determination end

        #When taxhousehold does not exist in your DB
        else
          self.set_determination_response_error!
          self.update_attributes(determination_http_status_code: 422, determination_error_message: "Failed to find Tax Households for the IDs in the XML")
          throw(:processing_issue, "ERROR: Failed to find Tax Households for the IDs in the XML")
        end
      end

      # th = tax_households.build(
      #   allocated_aptc: verified_tax_household.allocated_aptcs.first.total_amount,
      #   effective_starting_on: verified_tax_household.start_date,
      #   is_eligibility_determined: true,
      #   submitted_at: verified_tax_household.submitted_at
      # )

      # th.tax_household_members.build(
      #   family_member: primary_family_member,
      #   is_subscriber: true,
        # is_ia_eligible: verified_primary_tax_household_member.is_insurance_assistance_eligible ? verified_primary_tax_household_member.is_insurance_assistance_eligible : false
      # )

      # verified_primary_family_member.financial_statements.each do |fs|
      #   th.tax_household_members.first.financial_statements.build(
      #     tax_filing_status: fs.tax_filing_status.split('#').last,
      #     is_tax_filing_together: fs.is_tax_filing_together
      #   )

      #   th.tax_household_members.first.financial_statements.last.incomes.each do |i|
      #     th.tax_household_members.first.financial_statements.last.incomes.build(
      #       amount:
      #       end_date:
      #       frequency:
      #       start_date:
      #       submitted_date:
      #       type:
      #     )
      #   end
      # end

      # benchmark_plan_id = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.slcsp

      # latest_eligibility_determination = verified_tax_household.eligibility_determinations.max_by(&:determination_date)
      # th.eligibility_determinations.build(
      #   e_pdc_id: latest_eligibility_determination.id,
      #   benchmark_plan_id: benchmark_plan_id,
      #   max_aptc: latest_eligibility_determination.maximum_aptc,
      #   csr_percent_as_integer: latest_eligibility_determination.csr_percent,
      #   determined_on: latest_eligibility_determination.determination_date
      # )
      self.save!
    end
  end

  def add_tax_household_family_member(family_member, verified_tax_household_member)
    th = latest_active_tax_household
    th.tax_household_members.build(
      family_member: family_member,
      is_subscriber: false,
      is_ia_eligible: verified_tax_household_member.is_insurance_assistance_eligible
    )
    th.save!
  end

  def clean_conditional_params(model_params)
    clean_params(model_params)
  end

  def success_status_codes?(payload_http_status_code)
    [200, 203].include?(payload_http_status_code)
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

  def create_new_eligibility_determination(tax_household_id, verified_eligibility_determination, benchmark_plan_id, source)
    if eligibility_determinations.build(
      tax_household_id: tax_household_id,
      # e_pdc_id: verified_eligibility_determination.id,
      benchmark_plan_id: benchmark_plan_id,
      max_aptc: verified_eligibility_determination.maximum_aptc,
      csr_percent_as_integer: verified_eligibility_determination.csr_percent,
      csr_eligibility_kind: "csr_" + verified_eligibility_determination.csr_percent.to_s ,
      determined_at: verified_eligibility_determination.determination_date,
      determined_on: verified_eligibility_determination.determination_date,
      aptc_csr_annual_household_income: verified_eligibility_determination.aptc_csr_annual_household_income,
      aptc_annual_income_limit: verified_eligibility_determination.aptc_annual_income_limit,
      csr_annual_income_limit: verified_eligibility_determination.csr_annual_income_limit,
      source: source
    ).save!
    else
      throw(:processing_issue, "Failed to create Eligibility Determinations")
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
    write_attribute(:hbx_id, self.id)
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
    current_year = TimeKeeper.date_of_record.year
    assistance_year = HbxProfile.try(:current_hbx).try(:under_open_enrollment?) ? current_year + 1 : current_year
    update_attribute(:assistance_year, assistance_year)
  end

  def set_effective_date
    effective_date = HbxProfile.try(:current_hbx).try(:benefit_sponsorship).try(:earliest_effective_date)
    update_attribute(:effective_date, effective_date)
  end

  def set_benchmark_plan_id
    benchmark_plan_id = Plan.where(active_year: 2017, hios_id: "86052DC0400001-01").first.id
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

  def set_submit
    set_submission_date
    set_assistance_year
    set_effective_date
    create_tax_households
  end

  def unset_submit
    unset_submission_date
    unset_assistance_year
    unset_effective_date
    delete_tax_households
  end

  def create_tax_households
    ## Remove  when copy method is fixed to exclude copying Tax Household
    tax_households.destroy_all
    eligibility_determinations.destroy_all

    active_applicants.each { |applicant| applicant.update_attributes!(tax_household_id: nil)  }
    ##
    active_applicants.each do |applicant|
      if applicant.is_claimed_as_tax_dependent?
        # Assign applicant to the same THH that the person claiming this dependent belongs to.
        thh_of_claimer = active_applicants.find(applicant.claimed_as_tax_dependent_by).tax_household
        applicant.tax_household = thh_of_claimer if thh_of_claimer.present?
        applicant.update_attributes!(tax_filer_kind: 'dependent')
      elsif applicant.is_joint_tax_filing? && applicant.is_not_in_a_tax_household? && applicant.tax_household_of_spouse.present?
        # Assign joint filer to THH of Spouse.
        applicant.tax_household = applicant.tax_household_of_spouse
        applicant.update_attributes!(tax_filer_kind: 'tax_filer')
      else
        # Create a new THH and assign it to the applicant
        # Need THH for Medicaid cases too
        applicant.tax_household = tax_households.create!
        applicant.update_attributes!(tax_filer_kind: applicant.tax_filing? ? 'tax_filer' : 'non_filer')
      end
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
end
# eligibility_determinations.build( benchmark_plan_id: benchmark_plan_id, max_aptc: verified_eligibility_determination.maximum_aptc, csr_percent_as_integer: verified_eligibility_determination.csr_percent, csr_eligibility_kind: "csr_" + verified_eligibility_determination.csr_percent.to_s, determined_on: verified_eligibility_determination.determination_date, aptc_csr_annual_household_income: verified_eligibility_determination.aptc_csr_annual_household_income, aptc_annual_income_limit: verified_eligibility_determination.aptc_annual_income_limit, csr_annual_income_limit: verified_eligibility_determination.csr_annual_income_limit, source: source ).save!
