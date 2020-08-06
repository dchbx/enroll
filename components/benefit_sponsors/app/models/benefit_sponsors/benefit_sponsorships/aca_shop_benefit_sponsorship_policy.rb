# frozen_string_literal: true

module BenefitSponsors
  class BenefitSponsorships::AcaShopBenefitSponsorshipPolicy
    include BenefitMarkets::BusinessRulesEngine
    include Config::AcaModelConcern


    rule :stubbed_rule_one,
         validate: lambda { |_model_instance|
           true
         },
         fail: ->(_model_instance){ "something went wrong!!" },
         success: ->(_model_instance){ "validated successfully" }

    rule :stubbed_rule_two,
         validate: lambda { |_model_instance|
           true
         },
         fail: ->(_model_instance){ "something went wrong!!" },
         success: ->(_model_instance){ "validated successfully" }


    business_policy :stubbed_policy,
                    rules: [:stubbed_rule_one, :stubbed_rule_two]


    def business_policies_for(model_instance, _event_name)
      business_policies[:stubbed_policy] if model_instance.is_a?(BenefitSponsors::BenefitSponsorships::BenefitSponsorship)
    end
  end
end

