module Notifier
  module MergeDataModels
    class ConsumerRole
      include Virtus.model
      include ActiveModel::Model

      attribute :notice_date, String
      attribute :first_name, String
      attribute :last_name, String
      attribute :primary_fullname, String
      attribute :mailing_address, MergeDataModels::Address
      attribute :age, Integer
      attribute :ivl_oe_start_date, String
      attribute :ivl_oe_end_date, String
      attribute :dc_resident, String
      attribute :citizenship, String
      attribute :incarcerated, String
      attribute :other_coverage, String
      attribute :federal_tax_filing_status, String
      attribute :tax_household_size, Integer
      attribute :coverage_year, Integer
      attribute :expected_income_for_coverage_year, Float
      attribute :previous_coverage_year, Integer
      attribute :aptc, String
      attribute :dependents, Array[MergeDataModels::Dependent]
      attribute :magi_medicaid_members, Array[MergeDataModels::Dependent]
      attribute :aqhp_or_non_magi_medicaid_members, Array[MergeDataModels::Dependent]
      attribute :uqhp_or_non_magi_medicaid_members, Array[MergeDataModels::Dependent]
      attribute :addresses, Array[MergeDataModels::Address]
      attribute :aqhp_eligible, Boolean
      attribute :totally_ineligible, Boolean
      attribute :uqhp_eligible, Boolean
      attribute :irs_consent, Boolean
      attribute :magi_medicaid, Boolean
      attribute :non_magi_medicaid, Boolean
      attribute :csr, Boolean
      attribute :csr_percent, Integer
      attribute :aqhp_event, Boolean
      attribute :uqhp_event, Boolean
      attribute :magi_medicaid_members_present, Boolean
      attribute :aqhp_or_non_magi_medicaid_members_present, Boolean
      attribute :uqhp_or_non_magi_medicaid_members_present, Boolean
      attribute :totally_ineligible_members_present, Boolean
      attribute :irs_consent_not_needed, Boolean

      def self.stubbed_object
        notice = Notifier::MergeDataModels::ConsumerRole.new(
          {
            notice_date: TimeKeeper.date_of_record.strftime('%B %d, %Y'),
            first_name: 'Primary',
            last_name: 'Test',
            primary_fullname: 'Primary Test',
            age: 28,
            dc_resident: 'Yes',
            citizenship: 'US Citizen',
            incarcerated: 'No',
            other_coverage: 'No',
            coverage_year: 2020,
            previous_coverage_year: 2019,
            federal_tax_filing_status: 'Married Filing Jointly',
            expected_income_for_coverage_year: "$25,000",
            tax_household_size: 2,
            aptc: "$363.23",
            aqhp_eligible: true,
            uqhp_eligible: false,
            aqhp_event: true,
            uqhp_event: false,
            magi_medicaid_members_present: true,
            aqhp_or_non_magi_medicaid_members_present: true,
            uqhp_or_non_magi_medicaid_members_present: false,
            totally_ineligible_members_present: false,
            non_magi_medicaid: false,
            magi_medicaid: 'No',
            irs_consent: false,
            totally_ineligible: 'No',
            csr: true,
            csr_percent: 73,
            ivl_oe_start_date: Date.parse('November 01, 2019')
                                   .strftime('%B %d, %Y'),
            ivl_oe_end_date: Date.parse('January 31, 2020')
                                 .strftime('%B %d, %Y')
          }
        )

        notice.mailing_address = Notifier::MergeDataModels::Address.stubbed_object
        notice.addresses = [notice.mailing_address]
        notice.dependents = [Notifier::MergeDataModels::Dependent.stubbed_object]
        notice.aqhp_or_non_magi_medicaid_members = [notice]
        notice.magi_medicaid_members = [Notifier::MergeDataModels::Dependent.stubbed_object]
        notice
      end

      def collections
        %w[addresses dependents magi_medicaid_members aqhp_or_non_magi_medicaid_members uqhp_or_non_magi_medicaid_members]
      end

      def conditions
        %w[
            aqhp_eligible? uqhp_eligible? incarcerated? irs_consent?
            magi_medicaid? magi_medicaid_members_present? aqhp_or_non_magi_medicaid_members_present? uqhp_or_non_magi_medicaid_members_present?
            irs_consent_not_needed? aptc_amount_available? csr?
            aqhp_event_and_irs_consent_no? csr_is_73? csr_is_87?
            csr_is_94? csr_is_100? csr_is_zero? csr_is_nil? non_magi_medicaid?
            aptc_is_zero? totally_ineligible? aqhp_event? uqhp_event? totally_ineligible_members_present?
        ]
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
        aptc.present? && aptc.to_i >= 0
      end

      def aptc_is_zero?
        aptc.present? && aptc.gsub(/\D/, ' ').to_f.zero?
      end

      def csr?
        csr
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

      def aqhp_event_and_irs_consent_no?
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

      def csr_is_nil?
        csr_percent.nil?
      end

      def primary_address
        mailing_address
      end

      def shop?
        false
      end

      def individual?
        true
      end

      def consumer_role?
        true
      end
    end
  end
end