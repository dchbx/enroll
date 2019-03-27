module Notifier
  module MergeDataModels
    #Mergedatamodel attributes for FaaApplication of Eligibility and Ineligibility notice for Faa Application (IVL_ERA and IVL_NEL)
    class FaaApplication
      include Virtus.model
      include ActiveModel::Model

      attribute :notice_date, String
      attribute :application_date, String
      attribute :date_of_letter_45_days, String
      attribute :date_of_letter_95_days, String
      attribute :first_name, String
      attribute :last_name, String
      attribute :primary_fullname, String
      attribute :age, Integer
      attribute :effective_date, String
      attribute :max_aptc, String
      attribute :coverage_year, Integer
      attribute :coverage_year_oe_start_date, String
      attribute :coverage_year_oe_end_date, String
      attribute :monthly_household_income, String
      attribute :annual_household_income, String
      attribute :aptc_annual_income_limit, String
      attribute :csr_annual_income_limit, String
      attribute :csr_annual_allowable_limit, String
      attribute :ir1, String
      attribute :ir2, String
      attribute :ir3, String
      attribute :mailing_address, MergeDataModels::Address
      attribute :dependents, Array[MergeDataModels::Dependent]
      attribute :addresses, Array[MergeDataModels::Address]
      # attribute :dc_resident, String
      # attribute :citizenship, String
      # attribute :incarcerated, String
      # attribute :other_coverage, String
      # attribute :federal_tax_filing_status, String
      # attribute :tax_household_size, Integer
      # attribute :expected_income_for_coverage_year, Float
      # attribute :previous_coverage_year, Integer
      # attribute :aqhp_eligible, Boolean
      # attribute :totally_ineligible, Boolean
      # attribute :uqhp_eligible, Boolean
      # attribute :irs_consent, Boolean
      # attribute :magi_medicaid, Boolean
      # attribute :non_magi_medicaid, Boolean
      # attribute :csr, Boolean
      # attribute :csr_percent, Integer

      def self.stubbed_object
        notice = Notifier::MergeDataModels::FaaApplication.new(
          {
            notice_date: TimeKeeper.date_of_record.strftime('%B %d, %Y'),
            application_date: "11/10/2019",
            date_of_letter_45_days: "12/25/2019",
            date_of_letter_95_days:"02/15/2020",
            first_name: 'Samules',
            last_name: 'Parker',
            primary_fullname: 'Samules Parker',
            age: 28,
            effective_date:"02/01/2020",
            max_aptc: '575',
            coverage_year: "2020",
            coverage_year_oe_start_date: Date.parse('November 01, 2019')
                                   .strftime('%B %d, %Y'),
            coverage_year_oe_end_date: Date.parse('January 31, 2020')
                                 .strftime('%B %d, %Y'),
            monthly_household_income:"6000",
            annual_household_income:"76000",
            aptc_annual_income_limit:"110000",
            csr_annual_income_limit:"80000",
            csr_annual_allowable_limit:"70000"
            # coverage_year_oe_start_date:
            # coverage_year_oe_end_date:
            # dc_resident: 'Yes',
            # citizenship: 'US Citizen',
            # incarcerated: 'No',
            # other_coverage: 'No',

            # previous_coverage_year: 2019,
            # federal_tax_filing_status: 'Married Filing Jointly',
            # expected_income_for_coverage_year: "$25,000",
            # tax_household_size: 2,
            # aptc: '363.23',
            # aqhp_eligible: true,
            # uqhp_eligible: false,
            # totally_ineligible: false,
            # non_magi_medicaid: false,
            # magi_medicaid: false,
            # irs_consent: true,
            # csr: true,
            # csr_percent: 73,

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