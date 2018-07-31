module BenefitSponsors
  class BenefitSponsorships::AcaShopBenefitSponsorshipPolicy
    include BenefitMarkets::BusinessRulesEngine
    include Config::AcaModelConcern


    rule :stubbed_rule_one,
            validate: -> (model_instance) {
              true
            },
            fail:     -> (model_instance){ "something went wrong!!" },
            success:  -> (model_instance){ "validated successfully" }

    rule :stubbed_rule_two,
            validate: -> (model_instance) {
              true
            },
            fail:     -> (model_instance){ "something went wrong!!" },
            success:  -> (model_instance){ "validated successfully" }


    business_policy :stubbed_policy,
            rules: [ :stubbed_rule_one, :stubbed_rule_two ]


    def business_policies_for(model_instance, event_name)
      if model_instance.is_a?(BenefitSponsors::BenefitSponsorships::BenefitSponsorship)
        business_policies[:stubbed_policy]
      end
    end
  end
end

