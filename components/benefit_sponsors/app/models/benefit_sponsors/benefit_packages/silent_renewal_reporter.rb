# frozen_string_literal: true

module BenefitSponsors
  module BenefitPackages
    class SilentRenewalReporter
      def report_renewal_failure(_census_employee, _benefit_package, _failure); end

      def report_enrollment_renewal_exception(_hbx_enrollment, _exception); end

      def report_enrollment_save_renewal_failure(_hbx_enrollment, _model_errors); end
    end
  end
end