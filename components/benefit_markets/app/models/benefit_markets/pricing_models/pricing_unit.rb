module BenefitMarkets
  module PricingModels
    class PricingUnit
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :pricing_model, inverse_of: :pricing_units

      field :name, type: String
      field :display_name, type: String
      field :order, type: Integer

      validates_presence_of :name, :allow_blank => false
      validates_presence_of :display_name, :allow_blank => false
      validates_numericality_of :order, :allow_blank => false
    end
  end
end
