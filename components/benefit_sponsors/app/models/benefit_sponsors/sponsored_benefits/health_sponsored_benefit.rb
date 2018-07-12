module BenefitSponsors
  module SponsoredBenefits
    class HealthSponsoredBenefit < BenefitSponsors::SponsoredBenefits::SponsoredBenefit

      FILTER_MAP =  { 
                      issuer_profiles: -> { products.issuer_profiles },
                      # metal_level_kinds: BenefitMarkets::Products::HealthProducts::HealthProduct::METAL_LEVEL_KINDS,
                      health_plan_kinds: BenefitMarkets::Products::HealthProducts::HealthProduct::HEALTH_PLAN_MAP.keys,
                    }

    end
  end
end
