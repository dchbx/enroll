# frozen_string_literal: true

module Entities
  class ProductSelection < Dry::Struct
    transform_keys(&:to_sym)

    attribute :enrollment, ::Entities::Types.Nominal(HbxEnrollment)
    attribute :product, ::Entities::Types.Nominal(BenefitMarkets::Products::Product)
    attribute :family, ::Entities::Types.Nominal(Family)
  end
end