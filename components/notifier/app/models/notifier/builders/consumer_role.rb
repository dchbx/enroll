# frozen_string_literal: true
module Notifier
  module Builders
    class ConsumerRole
      # Builder class ConsumerRole for Projected Renewal Eligibility Notice- AQHP/UQHP

      include ActionView::Helpers::NumberHelper
      include Notifier::ApplicationHelper
      include Notifier::ConsumerRoleHelper
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

      def notice_date
        merge_model.notice_date = TimeKeeper.date_of_record
                                            .strftime('%B %d, %Y')
      end

      def first_name
        merge_model.first_name =
          if uqhp_notice? && consumer_role.present?
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

      def append_contact_details
        mailing_address = consumer_role.person.mailing_address
        return if mailing_address.blank?

        merge_model.mailing_address = address_hash(mailing_address)
      end

      def dependents
        payload['notice_params']['dependents'].each do |member|
          dependent = ::Notifier::Services::DependentService.new(uqhp_notice?, member)
          merge_model.dependents << dependent_hash(dependent, member)
        end
      end

      def magi_medicaid_members
        primary_member = []
        merge_model.magi_medicaid_members = []
        primary_member << payload['notice_params']['primary_member']
        dependent_members = payload['notice_params']['dependents']
        family_members = primary_member + dependent_members
        family_members.each do |member|
          next if member["magi_medicaid"] != "Yes"

          fam_member = ::Notifier::Services::DependentService.new(uqhp_notice?, member)
          merge_model.magi_medicaid_members << member_hash(fam_member)
        end
      end

      def aqhp_or_non_magi_medicaid_members
        primary_member = []
        merge_model.aqhp_or_non_magi_medicaid_members = []
        primary_member << payload['notice_params']['primary_member']
        dependent_members = payload['notice_params']['dependents']
        family_members = primary_member + dependent_members
        family_members.each do |member|
          next unless member["aqhp_eligible"] == "Yes" || member["non_magi_medicaid"] == "Yes"

          fam_member = ::Notifier::Services::DependentService.new(uqhp_notice?, member)
          merge_model.aqhp_or_non_magi_medicaid_members << member_hash(fam_member)
        end
      end

      def uqhp_or_non_magi_medicaid_members
        primary_member = []
        merge_model.uqhp_or_non_magi_medicaid_members = []
        primary_member << payload['notice_params']['primary_member']
        dependent_members = payload['notice_params']['dependents']
        family_members = primary_member + dependent_members
        family_members.each do |member|
          next unless member["uqhp_eligible"] == "Yes" || member["non_magi_medicaid"] == "Yes"

          fam_member = ::Notifier::Services::DependentService.new(uqhp_notice?, member)
          merge_model.uqhp_or_non_magi_medicaid_members << member_hash(fam_member)
        end
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
        merge_model.dc_resident =
          payload['notice_params']['primary_member']['resident'].capitalize
      end

      def expected_income_for_coverage_year
        merge_model.expected_income_for_coverage_year = expected_income_for_coverage_year_value(payload)
      end

      def federal_tax_filing_status
        merge_model.federal_tax_filing_status = filer_type(payload['notice_params']['primary_member']['filer_type'])
      end

      def citizenship
        merge_model.citizenship = citizen_status(payload['notice_params']['primary_member']['citizen_status'])
      end

      def tax_household_size
        merge_model.tax_household_size = payload['notice_params']['primary_member']['tax_hh_count'].to_i
      end

      def actual_income
        merge_model.actual_income = payload['notice_params']['primary_member']['actual_income'].to_i
      end

      def aqhp_eligible
        merge_model.aqhp_eligible =
          if uqhp_notice?
            false
          else
            payload['notice_params']['primary_member']['aqhp_eligible'].casecmp('YES').zero?
          end
      end

      def totally_ineligible
        merge_model.totally_ineligible =
          if uqhp_notice?
            false
          else
            payload['notice_params']['primary_member']['totally_inelig'].casecmp('YES').zero?
          end
      end

      def uqhp_eligible
        merge_model.uqhp_eligible =
          if uqhp_notice?
            true
          else
            payload['notice_params']['primary_member']['uqhp_eligible'].casecmp('YES').zero? ? true : false
          end
      end

      def incarcerated
        merge_model.incarcerated = (payload['notice_params']['primary_member']['incarcerated'] == 'N' || payload['notice_params']['primary_member']['incarcerated'] == '') ? 'No' : 'Yes'
      end

      def irs_consent
        merge_model.irs_consent =
          if uqhp_notice?
            false
          else
            payload['notice_params']['primary_member']['irs_consent'].casecmp('YES').zero?
          end
      end

      def magi_medicaid
        merge_model.magi_medicaid =
          if uqhp_notice?
            false
          else
            payload['notice_params']['primary_member']['magi_medicaid'].casecmp('YES').zero?
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
        merge_model.csr = payload['notice_params']['primary_member']['csr'].casecmp('YES').zero?
      end

      def aqhp_event
        merge_model.aqhp_event =  payload['notice_params']['aqhp_event'] == 'aqhp_projected_eligibility_notice_2'
      end

      def uqhp_event
        merge_model.uqhp_event =  payload['notice_params']['uqhp_event'] == 'uqhp_projected_eligibility_notice_1'
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
        payload['notice_params']['uqhp_event'] == 'uqhp_projected_eligibility_notice_1'
      end
    end
  end
end