module BenefitMarkets
  module PricingModels
    class PricingModel
      include Mongoid::Document
      include Mongoid::Timestamps

      field :name, type: String
      # Indicates the subclass of contribution unit value to be used under
      # our profiles.  This allows the contribution model to specify what
      # model should constrain the values need to be entered by the employer
      # without an explicit dependency.
      field :price_calculator_kind, type: String

      # Indicates the allowed multiplicity of products which may function with
      # this pricing model.  Should be some subset of :multiple and :single
      field :product_multiplicities, type: Array, default: [:multiple, :single]

      embeds_many :member_relationships, class_name: "::BenefitMarkets::PricingModels::MemberRelationship"
      embeds_many :pricing_units, class_name: "::BenefitMarkets::PricingModels::PricingUnit"

      validates_presence_of :pricing_units
      validates_presence_of :member_relationships
      validates_presence_of :price_calculator_kind, :allow_blank => false
      validates_presence_of :name, :allow_blank => false
      validates_presence_of :product_multiplicities, :allow_blank => false

      def pricing_calculator
        @pricing_calculator ||= price_calculator_kind.constantize.new
      end

      # Transform an external relationship into the mapped relationship
      # specified by this pricing model.
      def map_relationship_for(relationship, age, disability)
        found_relationship = member_relationships.detect { |mr| mr.match?(relationship, age, disability) }
        found_relationship.nil? ? nil : found_relationship.relationship_name
      end

      def create_copy_for_embedding
        new_pricing_model = BenefitMarkets::PricingModels::PricingModel.new(self.attributes.except(:pricing_units, :member_relationships))
        new_pricing_model.pricing_units = self.pricing_units.collect{ |pricing_unit| pricing_unit.class.new(pricing_unit.attributes) }
        new_pricing_model.member_relationships = self.member_relationships.collect{ |mr| mr.class.new(mr.attributes) }
        new_pricing_model
      end

      def pricing_units=(params)
        params.each do |param|
          if param.is_a?(BenefitMarkets::PricingModels::PricingUnit)
            pricing_units << param
          else
            pricing_units << pricing_unit_class.new(param)
          end
        end
      end

      def pricing_unit_class
        sub_class =
          if price_calculator_kind.demodulize.match?(/ListBillPricingCalculator/)
            "RelationshipPricingUnit"
          else
            "TieredPricingUnit"
          end
        "::BenefitMarkets::PricingModels::#{sub_class}".constantize
      end

      def find_by_pricing_unit(pricing_unit_id)
        pricing_units.find(pricing_unit_id)
      end
    end
  end
end
