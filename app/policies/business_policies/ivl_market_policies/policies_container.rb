# frozen_string_literal: true

module BusinessPolicies
  module IvlMarketPolicies
    class PoliciesContainer
      extend Dry::Container::Mixin

      register "aptc_policy_rules" do
        BusinessPolicies::IvlMarketPolicies::AptcPolicyRules.new
      end
    end
    IvlInjector = Dry::AutoInject(PoliciesContainer)
  end
end




