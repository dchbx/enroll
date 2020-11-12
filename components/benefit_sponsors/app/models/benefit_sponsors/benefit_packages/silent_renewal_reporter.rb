# frozen_string_literal: true

module BenefitSponsors
  module BenefitPackages
    class SilentRenewalReporter
      def report_renewal_failure(_census_employee, _benefit_package, _failure); end
    end
  end
end