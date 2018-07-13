module SponsoredBenefits
  module RatingModels
    class RatingTier
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :rating_model, class_name: "SponsoredBenefits::RatingModels::RatingModel"

      field :hbx_id,                            type: String
      field :title,                             type: String
      field :description,                       type: String, default: ""
      field :ordinal_position,                  type: Integer

      # Sponsor elects to offer contributions toward this rating tier
      field :is_offered,                        type: Boolean

      # Sponsor must offer contributions toward to this rating tier
      field :is_required,                       type: Boolean


      embeds_one  :sponsor_credit,
                  class_name: "SponsoredBenefits::RatingModels::CreditStructure"

      embeds_one  :member_relationship_map,
                  class_name: "SponsoredBenefits::RatingModels::MemberRelationshipMap"


      validates_presence_of :hbx_id, :is_offered, :is_required, 
                            :sponsor_credit, :member_relationship_map

      alias_method :is_offered?, :is_offered
      alias_method :is_required?, :is_required


      def sponsor_credit_structure_kind=(new_sponsor_credit_structure_kind)
        # Use same strategy as BenefitMarket#kind to associate the appropriate subclass here
      end

      # Return self if rating tier matches the enrollment group composition
      def match()
      end

    end
  end
end
