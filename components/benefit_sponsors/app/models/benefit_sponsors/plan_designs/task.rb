module BenefitSponsors
  module PlanDesigns
    class Task

      attr_accessor :sponsored_benefit, :parent

      def initialize(sponsored_benefit)
        @sponsored_benefit = sponsored_benefit
        
        # Pointer to traverse upward from child tasks
        # @parent = nil
      end

    end
  end
end
