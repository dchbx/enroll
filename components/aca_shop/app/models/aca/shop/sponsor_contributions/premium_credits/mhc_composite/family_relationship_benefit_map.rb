module Aca
  module Shop
    module SponsorContributions
      module PremiumCredits
        module MhcComposite
          class FamilyRelationshipBenefitMap
            include Mongoid::Document

              RELATIONSHIP_KINDS = [
                  :employee,
                  :spouse,
                  :domestic_partner,
                  :child_under_26,
                  :child_26_and_over
                ]

            embeds_many :family_relationship_benefit_items, class_name: "Aca::Shop::SponsorContributions::PremiumCredits::FamilyRelationshipBenefitItem"

          end
        end
      end
    end
  end
end