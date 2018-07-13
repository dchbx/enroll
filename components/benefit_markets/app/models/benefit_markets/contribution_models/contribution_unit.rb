module BenefitMarkets
  module ContributionModels
    class ContributionUnit
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :contribution_model, inverse_of: :contribution_units

      field :name, type: String
      field :display_name, type: String
      field :order, type: Integer

      embeds_many :member_relationship_maps, class_name: "::BenefitMarkets::ContributionModels::MemberRelationshipMap"

      validates_presence_of :name, :allow_blank => false
      validates_presence_of :display_name, :allow_blank => false
      validates_presence_of :member_relationship_maps, :allow_blank => false
      validates_numericality_of :order, :allow_blank => false

      def assign_contribution_value_defaults(cv)
        cv.contribution_unit_id = self.id
        cv.display_name = display_name
        cv.order = order
        cv.is_offered = true
      end

      def at_least_one_matches?(rel_hash)
        member_relationship_maps.any? do |mrm|
          mrm.match?(rel_hash)
        end
      end

      def match?(rel_hash)
        member_relationship_maps.all? do |mrm|
          mrm.match?(rel_hash)
        end
      end
    end
  end
end
