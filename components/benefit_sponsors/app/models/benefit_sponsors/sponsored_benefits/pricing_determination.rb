module BenefitSponsors
  module SponsoredBenefits
    class PricingDetermination
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :sponsored_benefit, class_name: "::BenefitSponsors::SponsoredBenefits::SponsoredBenefit", inverse_of: :pricing_determinations
      embeds_many :pricing_determination_tiers, class_name: "::BenefitSponsors::SponsoredBenefits::PricingDeterminationTier"

      delegate :pricing_model, to: :sponsored_benefit
      delegate :sponsor_contribution, to: :sponsored_benefit

      field :group_size, type: Integer, default: 1
      field :participation_rate, type: Float, default: 0.01

      def participation_percent
        participation_rate * 100.00
      end
    
    end
  end
end
