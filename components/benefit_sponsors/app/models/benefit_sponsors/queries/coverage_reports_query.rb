module BenefitSponsors
  module Queries
    class CoverageReportsQuery

      def initialize(employer_profile, billing_date)
        @employer_profile = employer_profile
        @billing_date = billing_date
      end

      def execute
        return coverage_report_adapter([]) if application.nil?
        @collection = []

        s_benefits = application.benefit_packages.map(&:sponsored_benefits).flatten
        criteria = s_benefits.map { |s_benefit| [s_benefit, query(s_benefit)] }.reject { |pair| pair.last.nil? }
        coverage_report_adapter(criteria)
      end

      def query(s_benefit)
        query = ::BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentsQuery.new(application, s_benefit).call(::Family, billing_report_date)
        return nil if query.count > 100
        query
      end

      def billing_date
        return @billing_date if @billing_date.present?
        @billing_date = billing_report_date
      end

      def billing_report_date
        return @billing_report_date if defined? @billing_report_date
        @billing_report_date = billing_adapter[:billing_date]
      end

      def application
        return @application if defined? @application
        @application = billing_adapter[:application]
      end

      def billing_adapter
        return @billing_adapter if defined? @billing_adapter
        billing_info = @employer_profile.billing_plan_year(@billing_date)
        @billing_adapter = {:application => billing_info[0], :billing_date => billing_info[1]}
      end

      def coverage_report_adapter(criteria)
        BenefitSponsors::LegacyCoverageReportAdapter.new(criteria)
      end
    end
  end
end
