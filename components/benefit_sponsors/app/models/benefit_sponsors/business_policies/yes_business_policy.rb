# frozen_string_literal: true

module BenefitSponsors
  module BusinessPolicies
    class YesBusinessPolicy
      include BenefitMarkets::BusinessRulesEngine
      include Config::AcaModelConcern


      rule :stubbed_rule_one,
           validate: lambda { |_model_instance|
             true
           },
           fail: ->(_model_instance) { "something went wrong!!" },
           success: ->(_model_instance) { "validated successfully" }

      rule :stubbed_rule_two,
           validate: lambda { |_model_instance|
             true
           },
           fail: ->(_model_instance) { "something went wrong!!" },
           success: ->(_model_instance) { "validated successfully" }


      business_policy :stubbed_policy,
                      rules: [:stubbed_rule_one, :stubbed_rule_two]


      def business_policies_for(_model_instance, _event_name)
        business_policies[:stubbed_policy]
      end
    end
  end
end
