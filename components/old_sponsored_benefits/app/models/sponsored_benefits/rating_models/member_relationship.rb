module SponsoredBenefits
  module RatingModels
    class MemberRelationship
      include Mongoid::Document
      include Mongoid::Timestamps


      embedded_in :member_relationship_map,
                  class_name: "SponsoredBenefits::RatingModels:MemberRelationshipMap"


      field :rating_tier,   type: Symbol
    

    end
  end
end
