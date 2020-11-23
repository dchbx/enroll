# frozen_string_literal: true

module Notifier
  module Builders
    class ConsumerRole
      # Builder class ConsumerRole for Projected Renewal Eligibility Notice- AQHP/UQHP

      include ActionView::Helpers::NumberHelper
      include Notifier::ApplicationHelper
      include Notifier::ConsumerRoleHelper
      include Notifier::EnrollmentHelper
      include Notifier::VerificationHelper
      include Config::ContactCenterHelper
      include Config::SiteHelper

      attr_accessor :consumer_role, :merge_model, :full_name, :payload,
                    :event_name, :sep_id

      delegate :person, to: :consumer_role

      def initialize
        data_object = Notifier::MergeDataModels::ConsumerRole.new
        data_object.mailing_address = Notifier::MergeDataModels::Address.new
        @merge_model = data_object
      end

      def resource=(resource)
        @consumer_role = resource
      end

      def append_data
        dependents
        enrollments
      end

      def notice_date
        merge_model.notice_date = TimeKeeper.date_of_record.strftime('%B %d, %Y')
      end

      def first_name
        merge_model.first_name = if uqhp_notice? && consumer_role.present?
                                   consumer_role.person.first_name
                                 else
                                   payload['notice_params']['primary_member']['first_name'].titleize
                                 end
      end

      def last_name
        merge_model.last_name =
          if uqhp_notice? && consumer_role.present?
            consumer_role.person.last_name
          else
            payload['notice_params']['primary_member']['last_name'].titleize
          end
      end

      def primary_fullname
        merge_model.primary_fullname = consumer_role.person.full_name.titleize if consumer_role.present?
      end

      def aptc
        merge_model.aptc =
          if uqhp_notice?
            nil
          else
            ActionController::Base.helpers.number_to_currency(payload['notice_params']['primary_member']['aptc'])
          end
      end

      def other_coverage
        merge_model.other_coverage =
          if uqhp_notice?
            nil
          else
            payload['notice_params']['primary_member']['mec'].presence || 'No'
          end
      end

      def age
        merge_model.age =
          if uqhp_notice?
            consumer_role.person.age_on(TimeKeeper.date_of_record)
          else
            age_of_aqhp_person(TimeKeeper.date_of_record, Date.strptime(payload['notice_params']['primary_member']['dob'],"%m/%d/%Y"))
          end
      end

      def family_members_hash
        primary_member = []
        primary_member << payload['notice_params']['primary_member']
        dependent_members = payload['notice_params']['dependents']
        members = primary_member + dependent_members
        members.compact
      end

      def append_contact_details
        mailing_address = consumer_role.person.mailing_address
        return if mailing_address.blank?

        merge_model.mailing_address = address_hash(mailing_address)
      end

      def primary_member
        member = payload['notice_params']['primary_member']
        dependent = ::Notifier::Services::DependentService.new(uqhp_notice?, member, renewing_enrollments)
        dependent_hash(dependent, member)
      end

      def family_members
        return @family_members if defined? @family_members
        @family_members = dependents + [primary_member]
      end

      def dependents
        primary_member = []
        primary_member << payload['notice_params']['primary_member']
        dependent_members = payload['notice_params']['dependents']
        members = primary_member + dependent_members
        merge_model.dependents =
          members.compact.uniq { |dependent| dependent['member_id'] }.collect do |member|
            dependent = ::Notifier::Services::DependentService.new(uqhp_notice?, member, renewing_enrollments)
            dependent_hash(dependent, member)
          end
      end

      # Loading only renewing enrollments
      def enrollments
        return [] unless renewing_enrollments.present?

        renewing_enrollments.each do |enrollment|
          merge_model.enrollments << enrollment_hash(enrollment)
        end
      end

      def tax_households
        tax_households = []
        primary_member = payload['notice_params']['primary_member']
        return [] unless primary_member['aqhp_eligible']&.upcase == "YES"

        thh = ::Notifier::Services::TaxHouseholdService.new(primary_member)
        tax_households << tax_households_hash(thh)
        merge_model.tax_households = tax_households
      end

      def tax_hh_with_csr
        tax_households.reject{ |thh| thh.csr_percent_as_integer == 100}
      end

      # there can be multiple health and dental enrollments for the same coverage year
      # Renewing health enrollments
      def aqhp_enrollments
        enrollments.select(&:is_receiving_assistance)
      end

      def renewing_health_enrollments
        renewing_enrollments.select { |e| e.coverage_kind == 'health' && e.effective_on.year.to_s == coverage_year.to_s}
      end

      def renewing_health_enrollments_present?
        renewing_health_enrollments.present?
      end

      # Renewing dental enrollments
      def renewing_dental_enrollments
        renewing_enrollments.select { |e| e.coverage_kind == 'dental' && e.effective_on.year.to_s == coverage_year.to_s }
      end

      # Current active health enrollments
      def current_health_enrollments
        active_enrollments.select { |e| e.coverage_kind == "health" && e.effective_on.year.to_s == previous_coverage_year.to_s}
      end

      # Current active dental enrollments
      def current_dental_enrollments
        active_enrollments.select { |e| e.coverage_kind == "dental" && e.effective_on.year.to_s == previous_coverage_year.to_s}
      end

      def renewal_csr_enrollments
        merge_model.enrollments.select { |enrollment| enrollment.product.is_csr }
      end

      def renewal_csr_enrollments_present?
        renewal_csr_enrollments.present?
      end

      # Renewing health product
      def renewing_health_products
        renewing_health_enrollments.map(&:product)
      end

      # Renewing dental product
      def renewing_dental_products
        renewing_dental_enrollments.map(&:product)
      end

      # Current active health products
      def current_health_products
        current_health_enrollments.map(&:product)
      end

      # Current active dental product
      def current_dental_products
        current_dental_enrollments.map(&:product)
      end

      def same_health_product
        merge_model.same_health_product = same_health_product?
      end

      def same_dental_product
        merge_model.same_dental_product = same_dental_product?
      end

      # checks if individual is enrolled into same health product
      def same_health_product?
        renewal_health_product_ids = current_health_products.map(&:renewal_product).map(&:id).compact
        passive_renewal_health_plan_ids = renewing_health_products.map(&:id).compact
        renewal_health_product_hios_base_ids = current_health_products.map(&:renewal_product).map(&:hios_base_id).compact
        passive_renewal_health_plan_hios_base_ids = renewing_health_products.map(&:hios_base_id).compact

        return false unless renewal_health_product_ids.present? && passive_renewal_health_plan_ids.present?

        (renewal_health_product_ids.sort == passive_renewal_health_plan_ids.sort) && (renewal_health_product_hios_base_ids.sort == passive_renewal_health_plan_hios_base_ids.sort)
      end

      # checks if individual is enrolled into same dental product
      def same_dental_product?
        renewal_dental_product_ids = current_dental_products.map(&:renewal_product).map(&:id).compact
        passive_renewal_dental_product_ids = renewing_dental_products.map(&:id).compact
        renewal_dental_product_hios_base_ids = current_dental_products.map(&:renewal_product).map(&:hios_base_id).compact
        passive_renewal_dental_product_hios_base_ids = renewing_dental_products.map(&:hios_base_id).compact

        return false unless renewal_dental_product_ids.present? && passive_renewal_dental_product_ids.present?

        (renewal_dental_product_ids.sort == passive_renewal_dental_product_ids.sort) && (renewal_dental_product_hios_base_ids.sort == passive_renewal_dental_product_hios_base_ids.sort)
      end

      def renewing_enrollments
        return [] unless payload['notice_params']['renewing_enrollment_ids'].present?

        payload['notice_params']['renewing_enrollment_ids'].collect do |hbx_id|
          HbxEnrollment.by_hbx_id(hbx_id).first
        end
      end

      def active_enrollments
        return [] unless payload['notice_params']['active_enrollment_ids'].present?

        payload['notice_params']['active_enrollment_ids'].collect do |hbx_id|
          HbxEnrollment.by_hbx_id(hbx_id).first
        end
      end

      def ineligible_applicants
        return nil unless family_members.present?

        merge_model.ineligible_applicants = family_members.select(&:totally_ineligible)
      end

      def magi_medicaid_members
        primary_member = []
        merge_model.magi_medicaid_members = []
        primary_member_object = payload['notice_params']['primary_member'].present? ? payload['notice_params']['primary_member'] : nil
        primary_member << primary_member_object
        dependent_members = payload['notice_params']['dependents']
        members = primary_member + dependent_members
        members.compact.uniq { |dependent| dependent['member_id'] }.each do |member|
          next if member["magi_medicaid"] != "Yes"

          fam_member = ::Notifier::Services::DependentService.new(uqhp_notice?, member, renewing_enrollments)
          merge_model.magi_medicaid_members << member_hash(fam_member)
        end
      end

      def aqhp_or_non_magi_medicaid_members
        primary_member = []
        merge_model.aqhp_or_non_magi_medicaid_members = []
        primary_member_object = payload['notice_params']['primary_member'].present? ? payload['notice_params']['primary_member'] : nil
        primary_member << primary_member_object
        dependent_members = payload['notice_params']['dependents']
        members = primary_member + dependent_members
        members.compact.uniq { |dependent| dependent['member_id'] }.each do |member|
          next unless member["aqhp_eligible"] == "Yes" || member["non_magi_medicaid"] == "Yes"

          fam_member = ::Notifier::Services::DependentService.new(uqhp_notice?, member, renewing_enrollments)
          merge_model.aqhp_or_non_magi_medicaid_members << member_hash(fam_member)
        end
      end

      def uqhp_or_non_magi_medicaid_members
        primary_member = []
        merge_model.uqhp_or_non_magi_medicaid_members = []
        primary_member_object = payload['notice_params']['primary_member'].present? ? payload['notice_params']['primary_member'] : nil
        primary_member << primary_member_object
        dependent_members = payload['notice_params']['dependents']
        members = primary_member + dependent_members
        members.compact.uniq { |dependent| dependent['member_id'] }.each do |member|
          next unless member["uqhp_eligible"] == "Yes" || member["non_magi_medicaid"] == "Yes"

          fam_member = ::Notifier::Services::DependentService.new(uqhp_notice?, member, renewing_enrollments)
          merge_model.uqhp_or_non_magi_medicaid_members << member_hash(fam_member)
        end
      end

      def family
        consumer_role&.person&.primary_family
      end

      def documents_needed
        merge_model.documents_needed =
          if uqhp_notice?
            unverified_individuals.present?
          else
            family_members_hash.any? { |member| member['docs_needed'].try(:upcase) == 'Y' }
          end
      end

      def unverified_individuals
        uqhp_notice? ? check_for_unverified_individuals(family) : family_members_hash
      end

      def ssa_unverified_individuals
        merge_model.ssa_unverified_individuals =
          unverified_individuals.collect do |individual|
            unverified_individual_hash(individual, due_date, uqhp_notice?) if ssn_outstanding?(individual, uqhp_notice?)
          end.compact
      end

      def dhs_unverified_individuals
        merge_model.dhs_unverified_individuals =
          unverified_individuals.collect do |individual|
            unverified_individual_hash(individual, due_date, uqhp_notice?) if lawful_presence_outstanding?(individual, uqhp_notice?)
          end.compact
      end

      def immigration_unverified_individuals
        merge_model.immigration_unverified_individuals =
          unverified_individuals.collect do |individual|
            unverified_individual_hash(individual, due_date, uqhp_notice?) if immigration_status_outstanding?(individual, uqhp_notice?)
          end.compact
      end

      def residency_inconsistency_individuals
        merge_model.residency_inconsistency_individuals =
          unverified_individuals.collect do |individual|
            unverified_individual_hash(individual, due_date, uqhp_notice?) if residency_outstanding?(individual, uqhp_notice?)
          end.compact
      end

      def american_indian_unverified_individuals
        merge_model.american_indian_unverified_individuals =
          unverified_individuals.collect do |individual|
            unverified_individual_hash(individual, due_date, uqhp_notice?) if american_indian_status_outstanding?(individual, uqhp_notice?)
          end.compact
      end

      def income_unverified_individuals
        merge_model.income_unverified_individuals =
          unverified_individuals.collect do |individual|
            unverified_individual_hash(individual, due_date, uqhp_notice?) if income_outstanding?(individual, uqhp_notice?)
          end.compact
      end

      def mec_conflict_individuals
        merge_model.mec_conflict_individuals =
          unverified_individuals.collect do |individual|
            unverified_individual_hash(individual, due_date, uqhp_notice?) if other_coverage_outstanding?(individual, uqhp_notice?)
          end.compact
      end

      def dhs_unverified_individuals_present
        dhs_unverified_individuals
        merge_model.dhs_unverified_individuals_present = merge_model.dhs_unverified_individuals.present?
      end

      def ssa_unverified_individuals_present
        ssa_unverified_individuals
        merge_model.ssa_unverified_individuals_present = merge_model.ssa_unverified_individuals.present?
      end

      def immigration_unverified_individuals_present
        immigration_unverified_individuals
        merge_model.immigration_unverified_individuals_present = merge_model.immigration_unverified_individuals.present?
      end

      def residency_inconsistency_individuals_present
        residency_inconsistency_individuals
        merge_model.residency_inconsistency_individuals_present = merge_model.residency_inconsistency_individuals.present?
      end

      def american_indian_unverified_individuals_present
        american_indian_unverified_individuals
        merge_model.american_indian_unverified_individuals_present = merge_model.american_indian_unverified_individuals.present?
      end

      def income_unverified_individuals_present
        income_unverified_individuals
        merge_model.income_unverified_individuals_present = merge_model.income_unverified_individuals.present?
      end

      def mec_conflict_individuals_present
        mec_conflict_individuals
        merge_model.mec_conflict_individuals_present = merge_model.mec_conflict_individuals.present?
      end

      def due_date
        return nil unless family

        merge_model.due_date = family.min_verification_due_date&.strftime('%B %d, %Y')
      end

      def ivl_oe_start_date
        merge_model.ivl_oe_start_date = ivl_oe_start_date_value
      end

      def ivl_oe_end_date
        merge_model.ivl_oe_end_date = ivl_oe_end_date_value
      end

      def coverage_year
        merge_model.coverage_year = TimeKeeper.date_of_record.next_year.year
      end

      def previous_coverage_year
        merge_model.previous_coverage_year = coverage_year.to_i - 1
      end

      def dc_resident
        return if primary_nil?
        merge_model.dc_resident = payload['notice_params']['primary_member']['resident'].capitalize
      end

      def expected_income_for_coverage_year
        return if uqhp_notice?
        merge_model.expected_income_for_coverage_year = expected_income_for_coverage_year_value(payload)
      end

      def federal_tax_filing_status
        return if primary_nil?
        merge_model.federal_tax_filing_status = filer_type(payload['notice_params']['primary_member']['filer_type'])
      end

      def citizenship
        return if primary_nil?

        merge_model.citizenship = ivl_citizen_status(uqhp_notice?, payload['notice_params']['primary_member']['citizen_status'])
      end

      def tax_household_size
        return if primary_nil?
        merge_model.tax_household_size = payload['notice_params']['primary_member']['tax_hh_count'].to_i
      end

      def actual_income
        return if primary_nil?
        merge_model.actual_income = payload['notice_params']['primary_member']['actual_income'].to_i
      end

      def aqhp_eligible
        merge_model.aqhp_eligible =
          if uqhp_notice?
            false
          else
            payload['notice_params']['primary_member']['aqhp_eligible']&.casecmp('YES')&.zero?
          end
      end

      def totally_ineligible
        merge_model.totally_ineligible =
          if uqhp_notice?
            false
          else
            payload['notice_params']['primary_member']['totally_inelig']&.casecmp('YES')&.zero?
          end
      end

      def uqhp_eligible
        merge_model.uqhp_eligible =
          if uqhp_notice?
            true
          else
            payload['notice_params']['primary_member']['uqhp_eligible']&.casecmp('YES')&.zero? ? true : false
          end
      end

      def incarcerated
        return if primary_nil?
        merge_model.incarcerated = (payload['notice_params']['primary_member']['incarcerated'] == 'N' || payload['notice_params']['primary_member']['incarcerated'] == '') ? 'No' : 'Yes'
      end

      def irs_consent
        merge_model.irs_consent =
          if uqhp_notice?
            false
          else
            payload['notice_params']['primary_member']['irs_consent']&.casecmp('YES')&.zero?
          end
      end

      def magi_medicaid
        merge_model.magi_medicaid =
          if uqhp_notice?
            false
          else
            payload['notice_params']['primary_member']['magi_medicaid']&.casecmp('YES')&.zero?
          end
      end

      def non_magi_medicaid
        merge_model.non_magi_medicaid =
          if uqhp_notice?
            true
          else
            payload['notice_params']['primary_member']['non_magi_medicaid'].casecmp('YES').zero?
          end
      end

      def csr
        return if primary_nil?
        merge_model.csr = payload['notice_params']['primary_member']['csr']&.casecmp('YES')&.zero?
      end

      def has_atleast_one_csr_member?
        csr? || dependents.any?(&:csr)
      end

      def primary_identifier
        merge_model.primary_identifier = consumer_role.person.hbx_id
      end

      def aqhp_event
        merge_model.aqhp_event = payload['notice_params']['uqhp_event'].upcase == 'AQHP'
      end

      def uqhp_event
        merge_model.uqhp_event = payload['notice_params']['uqhp_event'].upcase == 'UQHP'
      end

      def primary_member_present
        merge_model.primary_member_present = payload['notice_params']['primary_member'].present?
      end

      def primary_member_present?
        primary_member_present
      end

      def magi_medicaid_members_present
        magi_medicaid_members
        merge_model.magi_medicaid_members_present = merge_model.magi_medicaid_members.present?
      end

      def aqhp_or_non_magi_medicaid_members_present
        aqhp_or_non_magi_medicaid_members
        merge_model.aqhp_or_non_magi_medicaid_members_present = merge_model.aqhp_or_non_magi_medicaid_members.present?
      end

      def uqhp_or_non_magi_medicaid_members_present
        uqhp_or_non_magi_medicaid_members
        merge_model.uqhp_or_non_magi_medicaid_members_present = merge_model.uqhp_or_non_magi_medicaid_members.present?
      end

      def csr_percent
        return if primary_nil?
        merge_model.csr_percent = payload['notice_params']['primary_member']['csr_percent'].blank? ? nil : Integer(payload['notice_params']['primary_member']['csr_percent'])
      end

      def totally_ineligible_members_present
        merge_model.totally_ineligible_members_present = totally_ineligible? || merge_model.dependents.any?(&:totally_ineligible?)
      end

      def format_date(date)
        return '' if date.blank?

        date.strftime('%B %d, %Y')
      end

      def depents
        true
      end

      def aqhp_eligible?
        aqhp_eligible
      end

      def totally_ineligible?
        totally_ineligible
      end

      def uqhp_eligible?
        uqhp_eligible
      end

      def incarcerated?
        incarcerated.casecmp('NO').zero?
      end

      def irs_consent?
        irs_consent
      end

      def magi_medicaid?
        magi_medicaid
      end

      def non_magi_medicaid?
        non_magi_medicaid
      end

      def aptc_is_zero?
        aptc.present? && aptc.gsub(/\D/, ' ').to_f.zero?
      end

      def aqhp_or_non_magi_medicaid?
        aqhp_eligible? || non_magi_medicaid?
      end

      def uqhp_or_non_magi_medicaid?
        uqhp_eligible? || non_magi_medicaid?
      end

      def irs_consent_not_needed?
        !irs_consent
      end

      def aptc_amount_available?
        aptc.present?
      end

      def csr?
        return false if uqhp_notice?

        csr
      end

      def aqhp_event_and_irs_consent_no?
        return false if uqhp_notice?

        aqhp_event? && !irs_consent?
      end

      def csr_is_73?
        false unless csr?
        csr_percent == 73
      end

      def csr_is_87?
        false unless csr?
        csr_percent == 87
      end

      def csr_is_94?
        false unless csr?
        csr_percent == 94
      end

      def csr_is_100?
        false unless csr?
        csr_percent == 100
      end

      def csr_is_zero?
        false unless csr?
        csr_percent.zero?
      end

      def aqhp_event?
        aqhp_event
      end

      def uqhp_event?
        uqhp_event
      end

      def magi_medicaid_members_present?
        magi_medicaid_members_present
      end

      def aqhp_or_non_magi_medicaid_members_present?
        aqhp_or_non_magi_medicaid_members_present
      end

      def uqhp_or_non_magi_medicaid_members_present?
        uqhp_or_non_magi_medicaid_members_present
      end

      def totally_ineligible_members_present?
        totally_ineligible_members_present
      end

      def csr_is_nil?
        csr_percent.nil?
      end

      def citizen_status(status)
        if uqhp_notice?
          uqhp_citizen_status(status)
        else
          aqhp_citizen_status(status)
        end
      end

      def uqhp_notice?
        payload['notice_params']['uqhp_event'].upcase == 'UQHP'
      end

      def primary_nil?
        payload['notice_params']['primary_member'].nil?
      end
    end
  end
end