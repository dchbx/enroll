module BenefitMarkets
  module PricingModels
    class MemberRelationship
      include Mongoid::Document

      embedded_in :pricing_model, :inverse_of => :member_relationships

      field :relationship_name, type: Symbol
      field :relationship_kinds, type: Array
      field :age_threshold, type: Integer, default: nil
      field :age_comparison, type: Symbol, default: nil
      field :disability_qualifier, type: Boolean, default: nil

      validates_presence_of :relationship_name, :allow_blank => false
      validates_presence_of :relationship_kinds, :allow_blank => false

      def match?(relationship, age, dis)
        relationship_kinds.any? do |rk|
          (rk.to_s == relationship.to_s)
        end && matches_age(age) && matches_disability(dis)
      end

      def matches_age(age)
        return true if age_threshold.nil?
        case age_comparison
        when :>=
          age >= age_threshold
        else
          age < age_threshold
        end
      end

      def matches_disability(dis)
        return true if disability_qualifier.nil?
        (disability_qualifier == dis)
      end
    end
  end
end
