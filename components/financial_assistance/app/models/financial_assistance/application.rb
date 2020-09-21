# frozen_string_literal: true

module FinancialAssistance
  class Application # rubocop:disable Metrics/ClassLength TODO: Remove this

    include Mongoid::Document
    include Mongoid::Timestamps
    include AASM
    include Acapi::Notifiers
    require 'securerandom'

    # belongs_to :family, class_name: "Family"

    before_create :set_hbx_id, :set_applicant_kind, :set_request_kind, :set_motivation_kind, :set_us_state, :set_is_ridp_verified, :set_external_identifiers
    validates :application_submission_validity, presence: true, on: :submission
    validates :before_attestation_validity, presence: true, on: :before_attestation
    validate  :attestation_terms_on_parent_living_out_of_home

    YEARS_TO_RENEW_RANGE = (0..5).freeze
    RENEWAL_BASE_YEAR_RANGE = (2013..TimeKeeper.date_of_record.year + 1).freeze

    APPLICANT_KINDS   = ["user and/or family", "call center rep or case worker", "authorized representative"].freeze
    SOURCE_KINDS      = %w[paper source in-person].freeze
    REQUEST_KINDS     = %w[].freeze
    MOTIVATION_KINDS  = %w[insurance_affordability].freeze

    SUBMITTED_STATUS  = %w[submitted verifying_income].freeze
    REVIEWABLE_STATUSES = %w[submitted determination_response_error determined].freeze

    STATES_FOR_VERIFICATIONS = %w[submitted determination_response_error determined].freeze

    # TODO: Need enterprise ID assignment call for Assisted Application
    field :hbx_id, type: String

    ## Remove after data Cleanup ##
    field :external_id, type: String
    field :integrated_case_id, type: String
    ##
    field :family_id, type: BSON::ObjectId

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
    # Use `FinancialAssistanceRegistry[:application_year].item.call.value!` method in the Family model incase you need `assistance_year`
    # when aplication is in a `draft state`.
    field :assistance_year, type: Integer

    field :is_renewal_authorized, type: Boolean, default: true
    field :renewal_base_year, type: Integer
    field :years_to_renew, type: Integer

    field :is_requesting_voter_registration_application_in_mail, type: Boolean

    field :us_state, type: String
    field :benchmark_product_id, type: BSON::ObjectId

    field :medicaid_terms, type: Boolean
    field :medicaid_insurance_collection_terms, type: Boolean
    field :report_change_terms, type: Boolean
    field :parent_living_out_of_home_terms, type: Boolean
    field :attestation_terms, type: Boolean
    field :submission_terms, type: Boolean

    field :request_full_determination, type: Boolean
    field :integrated_case_id, type: String

    field :is_ridp_verified, type: Boolean
    field :determination_http_status_code, type: Integer
    field :determination_error_message, type: String
    field :has_eligibility_response, type: Boolean, default: false
    field :eligibility_response_payload, type: String

    field :workflow, type: Hash, default: { }

    embeds_many :eligibility_determinations, inverse_of: :application, class_name: '::FinancialAssistance::EligibilityDetermination'
    embeds_many :relationships, inverse_of: :application, class_name: '::FinancialAssistance::Relationship'
    embeds_many :applicants, inverse_of: :application, class_name: '::FinancialAssistance::Applicant'
    embeds_many :workflow_state_transitions, class_name: "WorkflowStateTransition", as: :transitional

    accepts_nested_attributes_for :applicants, :workflow_state_transitions

    # validates_presence_of :hbx_id, :applicant_kind, :request_kind, :benchmark_product_id

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
    scope :determined, ->{ any_in(aasm_state: "determined") }
    scope :by_hbx_id, ->(hbx_id) { where(hbx_id: hbx_id) }
    scope :for_verifications, -> { where(:aasm_state.in => STATES_FOR_VERIFICATIONS)}
    scope :by_year, ->(year) { where(:assistance_year => year) }

    alias is_joint_tax_filing? is_joint_tax_filing
    alias is_renewal_authorized? is_renewal_authorized

    def ensure_relationship_with_primary(applicant, relation_kind)
      update_or_build_relationship(applicant, primary_applicant, relation_kind)
      update_or_build_relationship(primary_applicant, applicant, ::FinancialAssistance::Relationship::INVERSE_MAP[relation_kind])
    end

    def update_or_build_relationship(applicant, relative, relation_kind)
      return if applicant.blank? || relative.blank? || relation_kind.blank?

      relationship = relationships.where(applicant_id: applicant.id, relative_id: relative.id).first
      if relationship.present?
        relationship.update(kind: relation_kind)
        return relationship
      end

      self.relationships << ::FinancialAssistance::Relationship.new(
        {
          kind: relation_kind,
          applicant_id: applicant.id,
          relative_id: relative.id
        }
      )
    end

    #TODO: start of work progress
    # Related to Relationship Matrix
    def add_relationship(predecessor, successor, relationship_kind, destroy_relation = false)
      if same_relative_exists?(predecessor, successor)
        direct_relationship = relationships.where(applicant_id: predecessor.id, relative_id: successor.id).first # Direct Relationship

        # Destroying the relationships associated to the Person other than the new updated relationship.
        if !direct_relationship.nil? && destroy_relation
          other_relations = relationships.where(applicant_id: predecessor.id, :id.nin => [direct_relationship.id]).map(&:relative_id)
          relationships.where(applicant_id: predecessor.id, :id.nin => [direct_relationship.id]).each(&:destroy)

          other_relations.each do |otr|
            otr_relation = relationships.where(applicant_id: otr, relative_id: predecessor.id).first
            otr_relation.destroy unless otr_relation.blank?
          end
        end

        direct_relationship.update(kind: relationship_kind)
      elsif predecessor.id != successor.id
        relationships.create(applicant_id: predecessor.id, relative_id: successor.id, kind: relationship_kind) # Direct Relationship
      end
    end

    def same_relative_exists?(predecessor, successor)
      relationships.where(applicant_id: predecessor.id, relative_id: successor.id).first.present?
    end

    #Used for RelationshipMatrix
    def build_relationship_matrix
      applicant_ids = active_applicants.map(&:id)
      matrix_size = applicant_ids.count
      matrix = Array.new(matrix_size){Array.new(matrix_size)}
      id_map = {}
      applicant_ids.each_with_index { |hmid, index| id_map.merge!(index => hmid) }
      matrix.each_with_index do |x, xi|
        x.each_with_index do |_y, yi|
          matrix[xi][yi] = find_existing_relationship(id_map[xi], id_map[yi])
          matrix[yi][xi] = find_existing_relationship(id_map[yi], id_map[xi])
        end
      end
      matrix = apply_rules_and_update_relationships(matrix)
      matrix
    end

    #update method as validate payload
    def update_application_and_applicant_attributes(payload)
      verified_family = Parsers::Xml::Cv::HavenVerifiedFamilyParser.new
      verified_family.parse(payload)

      update_response_attributes(integrated_case_id: verified_family.integrated_case_id)
      verified_primary_family_member = verified_family.family_members.detect{ |fm| fm.person.hbx_id == verified_family.primary_family_member_id }
      verified_dependents = verified_family.family_members.reject{ |fm| fm.person.hbx_id == verified_family.primary_family_member_id }
      primary_applicant = search_applicant(verified_primary_family_member)

      if primary_applicant.blank?
        update_application("Failed to find Primary Applicant on an Application", 422)
        return false
      end

      active_verified_household = verified_family.households.max_by(&:start_date)

      verified_dependents.each do |verified_family_member|
        if search_applicant(verified_family_member).blank?
          update_application("Failed to find Dependent Applicant on an Application", 422)
          return false
        end
      end
      build_or_update_applicants_eligibility_determinations(verified_family, primary_applicant, active_verified_household)
    end

    def build_or_update_applicants_eligibility_determinations(verified_family, _primary_applicant, active_verified_household)
      verified_tax_households = active_verified_household.tax_households.select{|th| th.primary_applicant_id == verified_family.primary_family_member_id}
      return unless verified_tax_households.present?

      ed_hbx_assigned_ids = []
      eligibility_determinations.each { |ed| ed_hbx_assigned_ids << ed.hbx_assigned_id.to_s}
      verified_tax_households.each do |vthh|
        if ed_hbx_assigned_ids.include?(vthh.hbx_assigned_id)
          eligibility_determination = eligibility_determinations.select{|ed| ed.hbx_assigned_id == vthh.hbx_assigned_id.to_i}.first
          #Update required attributes for that particular eligibility determination
          eligibility_determination.update_attributes(effective_starting_on: vthh.start_date, is_eligibility_determined: true)
          applicants_persons_hbx_ids = []
          applicants.each { |appl| applicants_persons_hbx_ids << appl.person_hbx_id.to_s}
          vthh.tax_household_members.each do |thhm|
            next unless applicants_persons_hbx_ids.include?(thhm.person_id)
            update_verified_applicants(self, verified_family, thhm)
          end
          update_eligibility_determinations(vthh, eligibility_determination) unless verified_tax_households.map(&:eligibility_determinations).map(&:present?).include?(false)
        else
          update_application("Failed to find eligibility determinations in our DB with the ids in xml", 422)
          return false
        end
      end
      self.save!
    end

    def update_eligibility_determinations(vthh, eligibility_determination)
      verified_eligibility_determination = vthh.eligibility_determinations.max_by(&:determination_date) #Finding the right Eligilbilty Determination
      #TODO: find the right source Curam/Haven.
      source = "Faa"

      verified_aptc = verified_eligibility_determination.maximum_aptc.to_f > 0.00 ? verified_eligibility_determination.maximum_aptc : 0.00
      eligibility_determination.update_attributes(
        max_aptc: verified_aptc,
        csr_percent_as_integer: verified_eligibility_determination.csr_percent,
        determined_at: verified_eligibility_determination.determination_date,
        aptc_csr_annual_household_income: verified_eligibility_determination.aptc_csr_annual_household_income,
        aptc_annual_income_limit: verified_eligibility_determination.aptc_annual_income_limit,
        csr_annual_income_limit: verified_eligibility_determination.csr_annual_income_limit,
        source: source
      )
    end

    def update_verified_applicants(application_in_context, verified_family, thhm)
      applicant = application_in_context.applicants.select { |app| app.person_hbx_id == thhm.person_id }.first
      verified_family.family_members.each do |verified_family_member|
        next unless verified_family_member.person.hbx_id == thhm.person_id
        applicant.update_attributes({medicaid_household_size: verified_family_member.medicaid_household_size,
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

    def find_existing_relationship(member_a_id, member_b_id)
      return 'self' if member_a_id == member_b_id

      rel = relationships.where(applicant_id: member_a_id, relative_id: member_b_id).first
      rel&.kind
    end

    def search_applicant(verified_family_member)
      ssn = verified_family_member.person_demographics.ssn
      ssn = '' if ssn == "999999999"
      dob = verified_family_member.person_demographics.birth_date
      last_name_regex = /^#{verified_family_member.person.name_last}$/i
      first_name_regex = /^#{verified_family_member.person.name_first}$/i

      if !ssn.blank?
        applicants.where({
                           :encrypted_ssn => FinancialAssistance::Applicant.encrypt_ssn(ssn),
                           :dob => dob
                         }).first
      else
        applicants.where({
                           :dob => dob,
                           :last_name => last_name_regex,
                           :first_name => first_name_regex
                         }).first
      end
    end

    def find_all_relationships(matrix)
      id_map = {}
      applicant_ids = active_applicants.map(&:id)
      applicant_ids.each_with_index { |hmid, index| id_map.merge!(index => hmid) }
      all_relationships = []
      matrix.each_with_index do |x, xi|
        x.each_with_index do |_y, yi|
          next unless xi < yi
          relation = relationships.where(applicant_id: id_map[xi], relative_id: id_map[yi]).first
          relation_kind = relation&.kind
          all_relationships << {:applicant => id_map[xi], :relation => relation_kind,  :relative => id_map[yi]}
        end
      end
      all_relationships
    end

    def find_missing_relationships(matrix)
      id_map = {}
      applicant_ids = active_applicants.map(&:id)
      applicant_ids.each_with_index { |hmid, index| id_map.merge!(index => hmid) }
      missing_relationships = []
      matrix.each_with_index do |x, xi|
        x.each_with_index do |_y, yi|
          missing_relationships << {id_map[xi] => id_map[yi]} if (xi > yi) && matrix[xi][yi].blank?
        end
      end
      missing_relationships
    end

    def update_response_attributes(attrs)
      update_attributes(attrs)
    end


    def add_eligibility_determination(message)
      update_response_attributes(message)
      ed_updated = update_application_and_applicant_attributes(message[:eligibility_response_payload])
      return unless ed_updated

      determine! # If successfully loaded ed's move the application to determined state
      result = ::Operations::Families::AddFinancialAssistanceEligibilityDetermination.new.call(params: self.attributes)
      result.failure? ? log(eligibility_response_payload, {:severity => 'critical', :error_message => "ERROR: #{result.failure}"}) : true
    end

    def update_application(error_message, status_code)
      set_determination_response_error!
      update_response_attributes(determination_http_status_code: status_code, has_eligibility_response: true, determination_error_message: error_message)
      log(eligibility_response_payload, {:severity => 'critical', :error_message => "ERROR: #{error_message}"})
    end

    def apply_rules_and_update_relationships(matrix) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
      missing_relationship = find_missing_relationships(matrix)

      # Sibling rule
      missing_relationship.each do |rel|
        first_rel = rel.to_a.flatten.first
        second_rel = rel.to_a.flatten.second
        relation1 = relationships.where(applicant_id: first_rel, kind: 'child').to_a
        relation2 = relationships.where(applicant_id: second_rel, kind: 'child').to_a

        relation = relation1 + relation2
        s_ids = relation.collect(&:relative_id)

        next unless s_ids.count > s_ids.uniq.count
        members = applicants.where(:id.in => rel.to_a.flatten)
        members.second.relationships.create(applicant_id: members.second.id, relative_id: members.first.id, kind: 'sibling')
        members.first.relationships.create(applicant_id: members.first.id, relative_id: members.second.id, kind: 'sibling')
        missing_relationship -= [rel] #Remove Updated Relation from list of missing relationships
      end

      #GrandParent/GrandChild
      missing_relationship.each do |rel|
        first_rel = rel.to_a.flatten.first
        second_rel = rel.to_a.flatten.second

        relation1 = relationships.where(applicant_id: first_rel, :kind.in => ['parent', 'child']).to_a
        relation2 = relationships.where(applicant_id: second_rel, :kind.in => ['parent', 'child']).to_a

        relation = relation1 + relation2
        s_ids = relation.collect(&:relative_id)

        s_ids.each do |p_id|
          parent_rel1 = relationships.where(relative_id: p_id, applicant_id: first_rel, kind: "parent").first
          child_rel1 = relationships.where(relative_id: p_id, applicant_id: first_rel, kind: "child").first
          parent_rel2 = relationships.where(relative_id: p_id, applicant_id: second_rel, kind: "parent").first
          child_rel2 = relationships.where(relative_id: p_id, applicant_id: second_rel, kind: "child").first

          if parent_rel1.present? && child_rel2.present?
            grandchild = applicants.where(id: second_rel).first
            grandparent = applicants.where(id: first_rel).first
            grandparent.relationships.create(applicant_id: grandparent.id, relative_id: grandchild.id, kind: "grandparent")
            grandchild.relationships.create(applicant_id: grandchild.id, relative_id: grandparent.id, kind: "grandchild")
            missing_relationship -= [rel] #Remove Updated Relation from list of missing relationships
            break
          elsif child_rel1.present? && parent_rel2.present?
            grandchild = applicants.where(id: first_rel).first
            grandparent = applicants.where(id: second_rel).first
            grandparent.relationships.create(applicant_id: grandparent.id, relative_id: grandchild.id, kind: "grandparent")
            grandchild.relationships.create(applicant_id: grandchild.id, relative_id: grandparent.id, kind: "grandchild")
            missing_relationship -= [rel] #Remove Updated Relation from list of missing relationships
            break
          end
        end
      end

      # Spouse Rule
      missing_relationship.each do |rel|
        first_rel = rel.to_a.flatten.first
        second_rel = rel.to_a.flatten.second

        parent_rel1 = relationships.where(applicant_id: first_rel, kind: 'child').first
        parent_rel2 = relationships.where(applicant_id: second_rel, kind: 'child').first

        next unless parent_rel1.present? && parent_rel2.present?
        spouse_relation = relationships.where(applicant_id: parent_rel1.relative_id, relative_id: parent_rel2.relative_id, kind: "spouse").first
        next unless spouse_relation.present?
        members = applicants.where(:id.in => rel.to_a.flatten)
        members.second.relationships.create(applicant_id: members.second.id, relative_id: members.first.id, kind: "sibling")
        members.first.relationships.create(applicant_id: members.first.id, relative_id: members.second.id, kind: "sibling")
        missing_relationship -= [rel] #Remove Updated Relation from list of missing relationships
      end

      matrix
    end
    #TODO: end of work progress

    # Set the benchmark product for this financial assistance application.
    # @param benchmark_product_id [ {Plan} ] The benchmark product for this application.
    # def benchmark_product=(new_benchmark_product)
    #   raise ArgumentError.new("expected Product") unless new_benchmark_product.is_a?(BenefitMarkets::Products::Product)
    #   write_attribute(:benchmark_plan_id, new_benchmark_product._id)
    #   @benchmark_product = new_benchmark_product
    # end

    # Set the benchmark plan for this financial assistance application.
    # @param benchmark_plan_id [ {Plan} ] The benchmark plan for this application.
    # def benchmark_plan=(new_benchmark_plan)
    #   raise ArgumentError.new("expected Plan") unless new_benchmark_plan.is_a?(Plan)
    #   write_attribute(:benchmark_plan_id, new_benchmark_plan._id)
    #   @benchmark_plan = new_benchmark_plan
    # end

    # Get the benchmark product for this application.
    # @return [ {Product} ] benchmark product
    # def benchmark_product
    #   return @benchmark_product if defined? @benchmark_product
    #   @benchmark_product = BenefitMarkets::Products::Product.find(benchmark_product_id) unless benchmark_product_id.blank?
    # end

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

    # Get the {FamilyMember} who is primary for this application.
    # @return [ {FamilyMember} ] primary {FamilyMember}
    def primary_applicant
      @primary_applicant ||= applicants.detect(&:is_primary_applicant?)
    end

    def find_applicant(id)
      applicants.find(id)
    end


    # TODO: define the states and transitions for Assisted Application workflow process
    aasm do
      state :draft, initial: true
      state :submitted
      state :determination_response_error
      state :determined

      event :submit, :after => [:record_transition, :set_submit] do
        transitions from: :draft, to: :submitted do
          guard do
            is_application_valid?
          end
        end

        transitions from: :draft, to: :draft, :after => :report_invalid do
          guard do
            !is_application_valid?
          end
        end
      end

      event :unsubmit, :after => [:record_transition, :unset_submit] do
        transitions from: :submitted, to: :draft do
          guard do
            true # add appropriate guard here
          end
        end
      end

      event :set_determination_response_error, :after => :record_transition do
        transitions from: :submitted, to: :determination_response_error
      end

      event :determine, :after => :record_transition do
        transitions from: :submitted, to: :determined
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

      return_value
    end

  ##### Methods below were transferred from EDI DB system
  ##### TODO: verify utility and improve names

    def compute_yearwise(incomes_or_deductions) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity TODO: Remove this
      income_deduction_per_year = Hash.new(0)

      incomes_or_deductions.each do |income_deduction|
        working_days_in_year = Float(52 * 5)
        daily_income = 0

        case income_deduction.frequency
        when "daily"
          daily_income = income_deduction.amount_in_cents
        when "weekly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year / 52)
        when "biweekly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year / 26)
        when "monthly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year / 12)
        when "quarterly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year / 4)
        when "half_yearly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year / 2)
        when "yearly"
          daily_income = income_deduction.amount_in_cents / working_days_in_year
        end

        income_deduction.start_date = TimeKeeper.date_of_record.beginning_of_year if income_deduction.start_date.to_s.eql?("01-01-0001" || income_deduction.start_date.blank?)
        income_deduction.end_date   = TimeKeeper.date_of_record.end_of_year if income_deduction.end_date.to_s.eql?("01-01-0001" || income_deduction.end_date.blank?)
        years = (income_deduction.start_date.year..income_deduction.end_date.year)

        years.to_a.each do |year|
          actual_days_worked = compute_actual_days_worked(year, income_deduction.start_date, income_deduction.end_date)
          income_deduction_per_year[year] += actual_days_worked * daily_income
        end
      end

      income_deduction_per_year.merge(income_deduction_per_year) do |_k, v|

        Integer(v)
      rescue StandardError
        v

      end
    end

    # Compute the actual days a applicant worked during one year
    def compute_actual_days_worked(year, start_date, end_date)
      working_days_in_year = Float(52 * 5)

      start_date_to_consider = if Date.new(year, 1, 1) < start_date
                                 start_date
                               else
                                 Date.new(year, 1, 1)
                               end

      end_date_to_consider = if Date.new(year, 1, 1).end_of_year < end_date
                               Date.new(year, 1, 1).end_of_year
                             else
                               end_date
                             end

      # we have to add one to include last day of work. We multiply by working_days_in_year/365 to remove weekends.
      ((end_date_to_consider - start_date_to_consider + 1).to_i * (working_days_in_year / 365)).to_i #actual days worked in 'year'
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
      true
    end

    def active_determined_eligibility_determinations
      eligibility_determinations.where(is_eligibility_determined: true)
    end

    def current_csr_percent_as_integer(eligibility_determination_id)
      eligibility_determination = eligibility_determination_for(eligibility_determination_id)
      eligibility_determination.present? ? eligibility_determination.csr_percent_as_integer : 0
    end

    def eligibility_determination_for(eligibility_determination_id)
      eligibility_determinations.where(id: eligibility_determination_id).first
    end

    def eligibility_determination_for_family_member(family_member_id)
      eligibility_determinations.where(is_eligibility_determined: true).select {|th| th if th.active_applicants.where(family_member_id: family_member_id).present? }.first
    end

    def latest_active_eligibility_determinations_with_year(year)
      eligibility_determinations = active_determined_eligibility_determinations.eligibility_determination_with_year(year)
      eligibility_determinations = active_determined_eligibility_determinations.eligibility_determination_with_year(year).active_eligibility_determination if TimeKeeper.date_of_record.year == year
      eligibility_determinations
    end

    def eligibility_determinations_for_year(year)
      return nil unless self.assistance_year == year
      self.eligibility_determinations
    end

    def complete?
      is_application_valid? # && check for the validity of applicants too.
    end

    def is_submitted?
      self.aasm_state == "submitted"
    end

    def send_failed_response
      unless has_eligibility_response
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

      return unless has_eligibility_response && determination_http_status_code == 422 && determination_error_message == "Failed to validate Eligibility Determination response XML"
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
              :primary_applicant_id => primary_applicant.person_hbx_id.to_s })
    end

    def ready_for_attestation?
      application_valid = is_application_ready_for_attestation?
      # && chec.k for the validity of all applicants too.
      self.active_applicants.each do |applicant|
        return false unless applicant.applicant_validation_complete?
      end
      application_valid && relationships_complete?
    end

    def relationships_complete?
      find_missing_relationships(build_relationship_matrix).present? ? false : true
    end

    def is_draft?
      self.aasm_state == "draft"
    end

    def is_determined?
      self.aasm_state == "determined"
    end

    def is_reviewable?
      REVIEWABLE_STATUSES.include?(aasm_state)
    end

    def incomplete_applicants?
      active_applicants.each do |applicant|
        return true unless applicant.applicant_validation_complete?
      end
      false
    end

    def next_incomplete_applicant
      active_applicants.each do |applicant|
        return applicant if applicant.applicant_validation_complete? == false
      end
    end

    def active_applicants
      applicants.where(:is_active => true)
    end

    def non_primary_applicants
      active_applicants.reject{|applicant| applicant == primary_applicant}
    end

    def clean_conditional_params(model_params)
      clean_params(model_params)
    end

    def success_status_codes?(payload_http_status_code)
      [200, 203].include?(payload_http_status_code)
    end

    def check_verification_response # rubocop:disable Metrics/CyclomaticComplexity
      return unless !has_all_uqhp_applicants? && !has_atleast_one_medicaid_applicant? && !has_all_verified_applicants? && (TimeKeeper.datetime_of_record.prev_day > submitted_at)
      return unless timeout_response_last_submitted_at.blank? || (timeout_response_last_submitted_at.present? && (TimeKeeper.datetime_of_record.prev_day > timeout_response_last_submitted_at))
      self.update_attributes(timeout_response_last_submitted_at: TimeKeeper.datetime_of_record)
      active_applicants.each do |applicant|
        if !applicant.has_income_verification_response && !applicant.has_mec_verification_response
          type = "Income, MEC"
        elsif applicant.has_income_verification_response && !applicant.has_mec_verification_response
          type = "MEC"
        elsif !applicant.has_income_verification_response && applicant.has_mec_verification_response
          type = "Income"
        end
        notify("acapi.info.events.verification.rejected",
               { :correlation_id => SecureRandom.uuid.gsub("-",""),
                 :body => JSON.dump({
                                      error: "Timed-out waiting for verification response",
                                      applicant_first_name: applicant.first_name,
                                      applicant_last_name: applicant.last_name,
                                      applicant_id: applicant.person_hbx_id,
                                      rejected_verification_types: type
                                    }),
                 :assistance_application_id => self._id.to_s,
                 :family_id => self.family_id.to_s,
                 :haven_application_id => haven_app_id,
                 :haven_ic_id => haven_ic_id,
                 :reject_status => 504,
                 :submitted_timestamp => TimeKeeper.datetime_of_record.strftime('%Y-%m-%dT%H:%M:%S')})
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

    private

    def clean_params(model_params)
      model_params[:attestation_terms] = nil if model_params[:parent_living_out_of_home_terms].present? && model_params[:parent_living_out_of_home_terms] == 'false'
      model_params[:years_to_renew] = "5" if model_params[:is_renewal_authorized].present? && model_params[:is_renewal_authorized] == "true"
    end

    def attestation_terms_on_parent_living_out_of_home
      return unless parent_living_out_of_home_terms
      errors.add(:attestation_terms, "can't be blank") if attestation_terms.nil?
    end

    def trigger_eligibilility_notice
      if is_family_totally_ineligibile
        IvlNoticesNotifierJob.perform_later(self.primary_applicant.id.to_s, "ineligibility_notice")
      else
        IvlNoticesNotifierJob.perform_later(self.primary_applicant.id.to_s, "eligibility_notice")
      end
    end

    def set_hbx_id
      #TODO: Use hbx_id generator for Application
      write_attribute(:hbx_id, FinancialAssistance::HbxIdGenerator.generate_application_id) if hbx_id.blank?
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
      write_attribute(:us_state, FinancialAssistanceRegistry[:us_state].setting(:abbreviation).item)
    end

    def set_submission_date
      update_attribute(:submitted_at, Time.current)
    end

    def set_assistance_year
      update_attribute(:assistance_year, FinancialAssistanceRegistry[:application_year].item.call.value!)
    end

    def set_effective_date
      effective_date = FinancialAssistanceRegistry[:earliest_effective_date].item.call.value!
      update_attribute(:effective_date, effective_date)
    end

    # def set_benchmark_product_id
    #   benchmark_product_id = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.slcsp
    #   write_attribute(:benchmark_product_id, benchmark_product_id)
    # end

    def active_approved_application
      self.class.where(aasm_state: "determined", family_id: family_id, assistance_year: FinancialAssistanceRegistry[:application_year].item.call.value!).order_by(:submitted_at => 'desc').first if family_id.present?
    end

    def set_external_identifiers
      app = active_approved_application
      return unless app.present?
      write_attribute(:haven_app_id, app.haven_app_id)
      write_attribute(:haven_ic_id, app.haven_ic_id)
      write_attribute(:e_case_id, app.e_case_id)
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

      if relationships_complete?
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
      return unless aasm_state == "determined"
      if has_atleast_one_medicaid_applicant?
        update_verifications_of_applicants("external_source")
      elsif has_all_uqhp_applicants?
        update_verifications_of_applicants("not_required")
      elsif has_atleast_one_assisted_but_no_medicaid_applicant?
        update_verifications_of_applicants("pending")
      end
    end

    def set_submit
      return unless submitted?
      set_submission_date
      set_assistance_year
      set_effective_date
      create_eligibility_determinations
      create_verification_documents
    end

    def unset_submit
      unset_submission_date
      unset_assistance_year
      unset_effective_date
      delete_eligibility_determinations
      delete_verification_documents
    end

    def create_eligibility_determinations
      ## Remove  when copy method is fixed to exclude copying Tax Household
      active_applicants.each { |applicant| applicant.update_attributes!(eligibility_determination_id: nil)  }

      non_tax_dependents = active_applicants.where(is_claimed_as_tax_dependent: false)
      tax_dependents = active_applicants.where(is_claimed_as_tax_dependent: true)

      non_tax_dependents.each do |applicant|
        if applicant.is_joint_tax_filing? && applicant.is_not_in_a_tax_household? && applicant.eligibility_determination_of_spouse.present?
          applicant.eligibility_determination = applicant.eligibility_determination_of_spouse
          applicant.update_attributes!(tax_filer_kind: 'tax_filer')
        else
          # Create a new THH and assign it to the applicant
          # Need THH for Medicaid cases too
          applicant.eligibility_determination = eligibility_determinations.create!
          applicant.update_attributes!(tax_filer_kind: applicant.tax_filing? ? 'tax_filer' : 'non_filer')
        end
      end

      tax_dependents.each do |applicant|
        thh_of_claimer = non_tax_dependents.find(applicant.claimed_as_tax_dependent_by).eligibility_determination
        applicant.eligibility_determination = thh_of_claimer if thh_of_claimer.present?
        applicant.update_attributes!(tax_filer_kind: 'dependent')
        applicant.update_attributes!(tax_filer_kind: 'dependent')
      end

      empty_ed = eligibility_determinations.select do |ed|
        active_applicants.map(&:eligibility_determination).exclude?(ed)
      end
      empty_ed.each(&:destroy)
    end

    def delete_eligibility_determinations
      eligibility_determinations.destroy_all
    end

    def create_verification_documents
      active_applicants.each do |applicant|
        applicant.verification_types =
          %w[Income MEC].collect do |type|
            VerificationType.new(type_name: type, validation_status: 'pending')
          end
        applicant.move_to_pending!        
      end
    end

    def delete_verification_documents
      active_applicants.each do |applicant|
        applicant.verification_types.destroy_all
        applicant.move_to_unverified!
      end
    end
  end
end
