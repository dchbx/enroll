module SponsoredBenefits
  module RatingModels
    class MemberRelationshipMap
      include Mongoid::Document
      include Mongoid::Timestamps

      ACA_SHOP_RELATIONSHIP_KINDS =       [
                                            :self, 
                                            :survivor,
                                            :spouse, 
                                            :domestic_partner, 
                                            :child_under_26, 
                                            :disabled_children_26_and_over,
                                            :child_26_and_over,
                                          ]

      ACA_INDIVIDUAL_RELATIONSHIP_KINDS = [
                                            :self,
                                            :survivor,
                                            :spouse,
                                            :domestic_partner,
                                            :child,
                                            :parent,
                                            :sibling,
                                            :ward,
                                            :guardian,
                                            :unrelated,
                                            :other_tax_dependent,
                                            :aunt_or_uncle,
                                            :nephew_or_niece,
                                            :grandchild,
                                            :grandparent,
                                          ]

      RELATIONSHIPS_UI =                  [
                                            :self,
                                            :survivor, 
                                            :spouse,
                                            :domestic_partner,
                                            :child,
                                            :parent,
                                            :sibling,
                                            :unrelated,
                                            :aunt_or_uncle,
                                            :nephew_or_niece,
                                            :grandchild,
                                            :grandparent,
                                          ]


      embedded_in :rating_tier, class_name: "SponsoredBenefits::RatingModels::RatingTier"


      embeds_many :member_relationships,
                  class_name: "SponsoredBenefits::RatingModels:MemberRelationship"


      validates_presence_of :member_relationships


      # TODO
      # Build a relationship_map for the given member set
      def relationship_map_for(enrollment_group)

        # Fold enrollment group into relationship_map

        # MA relationships
        # :employee,  # => employee
        # :survivor,  # => survivor
        # :spouse,    # => spouse, domestic partner, 
        # :dependent, # => child + age < 26, child + is_disabled? 


        # Congress relationships
        # :employee,  # => employee, survivor
        # :survivor,  # => survivor
        # :dependent, # => spouse, domestic partner, child, child + age < 26, child + is_disabled? 

        relationship_map
      end


      # TODO
      # Return the rating tier that matches the primary member's enrollment group
      def rating_tier_for(relationship_map)

        # MA mapping
        # employee_only:                        :employee == 1, :spouse == 0, :dependent == 0, :survivor == 0
        # employee_and_spouse_only:             :employee == 1, :spouse == 1, :dependent == 0, :survivor == 0
        # employee_and_one_or_more_dependents:  :employee == 1, :spouse == 0, :dependent > 0,  :survivor == 0
        # family:                               :employee == 1, :spouse == 1, :dependent > 0,  :survivor == 0

        # Congress mapping
        # employee_only:                        :employee == 1, :spouse == 0, :dependent == 0, :survivor == 0
        # employee_and_one_dependent:           :employee == 1, :spouse == 0, :dependent == 1, :survivor == 0
        # employee_and_two_or_more_dependents:  :employee == 1, :spouse == 0, :dependent > 1,  :survivor == 0

        rating_tier
      end

    end
  end
end
