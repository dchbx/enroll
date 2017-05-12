module Aca
  module Shop
    module SponsorContributions
      module PremiumCredits
        class BaseRatingFactor
          include Mongoid::Document
          include Mongoid::Timestamps

          RATING_FACTOR_CLASS_NAME = "RatingFactor"
          FAMILY_RELATIONSHIP_BENEFIT_MAP_CLASS_NAME = "FamilyRelationshipBenefitMap"

          def self.included(base)
            base.extend ClassMethods
          end
        end

        module ClassMethods

          def namespace
            full_klass_name = self.class.name
            klass_name = full_klass_name.split("::").last
            full_klass_name.partition("::" + klass_name).first
          end

          def rating_factor_class_name
            namespace + "::" + RATING_FACTOR_CLASS_NAME
          end

          def family_relationship_benefit_map_class_name
            namespace + "::" + FAMILY_RELATIONSHIP_BENEFIT_MAP_CLASS_NAME
          end

          def set_embedded_relationships
            embeds_one  :rating_factor, class_name: rating_factor_class_name
            embeds_many :family_relationship_benefit_maps, class_name: family_relationship_benefit_map_class_name
          end

        end

      end
    end
  end
end