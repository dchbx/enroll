module BenefitMarkets
  module Products
    module ActuarialFactors
      class ActuarialFactorEntry
        include Mongoid::Document

        embedded_in :actuarial_factors, class_name: "::BenefitMarkets::Products::ActuarialFactors::ActuarialFactor"

        field :factor_key, type: String
        field :factor_value, type: Float

        validates_numericality_of :factor_value, :allow_blank => false
        validates_presence_of :factor_key, :allow_blank => false
      end
    end
  end
end
