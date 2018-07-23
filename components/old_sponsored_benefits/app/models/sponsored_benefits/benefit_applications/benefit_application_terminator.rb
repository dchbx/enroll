module SponsoredBenefits
  module BenefitApplications
    class BenefitApplicationTerminator

      def initialize(benefit_application, termination_date = nil)
        @benefit_application  = benefit_application
        @benefit_sponsor      = @benefit_application.parent
        @termination_date     = termination_date || @benefit_application.effective_period.end
      end

      def terminate
        return unless may_terminate?

        terminate_members
        terminate_application

        @benefit_application
      end

      def may_terminate?
        return false unless @benefit_application && @benefit_sponsor && @termination_date
      end

      private

      def terminate_member_enrollments(member)
      end

      def terminate_members
      end

      def terminate_application
      end


    end
  end
end
