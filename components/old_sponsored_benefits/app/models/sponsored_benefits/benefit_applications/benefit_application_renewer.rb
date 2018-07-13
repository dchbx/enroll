module SponsoredBenefits
  module BenefitApplications
    class BenefitApplicationRenewer

      def initialize(benefit_application, renewal_effective_date = nil)
        @benefit_application          = benefit_application
        @benefit_sponsor              = @benefit_application.parent
        @renewal_effective_date       = renewal_effective_date || (@benefit_application.effective_period.end + 1.day)
        @renewed_benefit_application  = SponsoredBenefits::BenefitApplications::BenefitApplication.new
      end

      # Return new instance of application in renewing state
      def renew
        return unless may_renew?

        renew_application
        @renewed_benefit_application
      end

      def may_renew?
        return false unless @benefit_application && @benefit_sponsor && @renewal_effective_date
      end

      private

      def renewal_application

      end

    end
  end
end
