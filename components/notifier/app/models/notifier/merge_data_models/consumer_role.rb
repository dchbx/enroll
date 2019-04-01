module Notifier
  module MergeDataModels
    #Mergedatamodel attributes for consumer_role of AQHP/UQHP in Projected Renewal Eligibilty Notice
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
      attribute :addresses, Array[MergeDataModels::Address]
      attribute :aqhp_eligible, Boolean
      attribute :totally_ineligible, Boolean
      attribute :uqhp_eligible, Boolean
      attribute :irs_consent, Boolean
      attribute :magi_medicaid, Boolean
      attribute :non_magi_medicaid, Boolean
      attribute :csr, Boolean
      attribute :csr_percent, Integer

      def self.stubbed_object
        notice = Notifier::MergeDataModels::ConsumerRole.new(
          {
            notice_date: TimeKeeper.date_of_record.strftime('%B %d, %Y'),
            first_name: 'Samules',
            last_name: 'Parker',
            primary_fullname: 'Samules Parker',
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
            aptc: '363.23',
            aqhp_eligible: true,
            uqhp_eligible: false,
            totally_ineligible: false,
            non_magi_medicaid: false,
            magi_medicaid: false,
            irs_consent: true,
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
        notice
      end

      def collections
        %w[addresses dependents]
      end

      def conditions
        %w[
            aqhp_eligible? uqhp_eligible? incarcerated? irs_consent?
            magi_medicaid? aqhp_or_non_magi_medicaid? uqhp_or_non_magi_medicaid?
            irs_consent_not_needed? aptc_amount_available? csr?
            aqhp_eligible_and_irs_consent_not_needed? csr_is_73? csr_is_87?
            csr_is_94? csr_is_100? csr_is_zero? csr_is_nil? non_magi_medicaid?
            aptc_is_zero? totally_ineligible?
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
        aptc.present? && aptc.to_i > 0
      end

      def aptc_is_zero?
        aptc.present? && aptc.to_i.zero?
      end

      def csr?
        csr
      end

      def aqhp_eligible_and_irs_consent_not_needed?
        aqhp_eligible? && !irs_consent?
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
