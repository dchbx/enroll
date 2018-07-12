module BenefitMarkets
  module PricingModels
    class TieredPricingUnit < PricingUnit
      embeds_many :member_relationship_maps, class_name: "::BenefitMarkets::PricingModels::MemberRelationshipMap"
      validates_presence_of :member_relationship_maps, :allow_blank => false

      def match?(rel_hash)
        member_relationship_maps.all? do |mrm|
          mrm.match?(rel_hash)
        end
      end
    end
  end
end
