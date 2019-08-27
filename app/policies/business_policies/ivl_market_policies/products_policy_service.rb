# frozen_string_literal: true

module BusinessPolicies
  module IvlMarketPolicies
    class ProductsPolicyService

      def initialize
        puts "ivl_enrollment_policies"
      end

      def apply_policies
        @policies.each do |policy|
          policy = PoliciesContainer[policy]
          policy.execute(enrollment)
        end
      end
    end
  end
end


