module BenefitMarkets
  module ContributionModels
    class ContributionModel
      include Mongoid::Document
      include Mongoid::Timestamps

      field :title, type: String
      field :key,   type: Symbol

      # Indicates the instance of sponsor contribution to be used under
      # our profiles.  This allows the contribution model to specify what
      # model should constrain the values need to be entered by the employer
      # without an explicit dependency.
      field :sponsor_contribution_kind, type: String

      # Indicates the subclass of contribution calculator to be used
      # under our profiles
      field :contribution_calculator_kind, type: String

      # Will an enrollment map to multiple possible contribution units?
      field :many_simultaneous_contribution_units, type: Boolean, default: false

      # Indicates the set of product multiplicities that are compatible
      # with this contribution model.  Should be some subset of 
      # :multiple, :single. 
      field :product_multiplicities, type: Array, default: [:multiple, :single]

      embeds_many :contribution_units, class_name: "::BenefitMarkets::ContributionModels::ContributionUnit"
      embeds_many :member_relationships, class_name: "::BenefitMarkets::ContributionModels::MemberRelationship"

      validates_presence_of :title, :allow_blank => false
      validates_presence_of :contribution_units
      validates_presence_of :sponsor_contribution_kind, :allow_blank => false
      validates_presence_of :contribution_calculator_kind, :allow_blank => false
      validates_presence_of :member_relationships
      validates_presence_of :product_multiplicities, :allow_blank => false

      index({"key" => 1})

      scope :options_for_select,  ->{ unscoped.distinct(:key).as_json } #.reduce([]) { |list, cm| list << [cm.title, cm.key] } }

      def contribution_calculator
        @contribution_calculator ||= contribution_calculator_kind.constantize.new
      end

      # Transform an external relationship into the mapped relationship
      # specified by this contribution model.
      def map_relationship_for(relationship, age, disability)
        found_rel = member_relationships.detect { |mr| mr.match?(relationship, age, disability) }
        found_rel ? found_rel.relationship_name : nil
      end

      def many_simultaneous_contribution_units?
        many_simultaneous_contribution_units
      end

      def create_copy_for_embedding
        new_contribution_model = self.class.new(self.attributes.except(:contribution_units, :member_relationships))
        new_contribution_model.contribution_units = self.contribution_units.collect{ |contribution_unit| contribution_unit.class.new(contribution_unit.attributes) }
        new_contribution_model.member_relationships = self.member_relationships.collect{ |mr| mr.class.new(mr.attributes) }
        new_contribution_model
      end

      def find_contribution_unit(contribution_unit_id)
        contribution_units.find(contribution_unit_id)
      end
    end
  end
end
