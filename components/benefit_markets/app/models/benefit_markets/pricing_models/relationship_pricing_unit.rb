module BenefitMarkets
  module PricingModels
    class RelationshipPricingUnit < PricingUnit
      field :discounted_above_threshold, type: Integer
      field :eligible_for_threshold_discount, type: Boolean, default: false

      validates_numericality_of :discounted_above_threshold, greater_than_or_equal_to: 0, allow_nil: true

      validate :threshold_provided_if_eligible
      validate :name_matches_relationship

      def threshold_provided_if_eligible
        if eligible_for_threshold_discount
          if discounted_above_threshold.blank?
            errors.add(:discounted_above_threshold, "you must provide a value for the discount threshold if the relationship is eligible for discounting")
          end
        end
        true
      end

      def name_matches_relationship
        return true if pricing_model.blank?
        return true if pricing_model.member_relationships.blank?
        matching_relationship = pricing_model.member_relationships.select { |mr| mr.relationship_name.to_sym == name.to_sym }
        if !matching_relationship.any?
          errors.add(:name, "the name of a relationship pricing unit must match the name of a mapped relationship")
        end
        true
      end
    end
  end
end
