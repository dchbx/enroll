module Aca
  module Shop
    # Service class for terminating employer sponsored active benefit
    class BenefitEnrollmentTerminator

      def initialize(employer_profile, benefit_kind, termination_date)
        @employer_profile = employer_profile
        @benefit_kind     = benefit_kind
        @termination_date = termination_date
      end

      def terminate
        return false unless @employer_profile && @benefit_kind && @termination_date
      end


    end
  end
end