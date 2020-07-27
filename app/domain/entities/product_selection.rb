# frozen_string_literal: true

module Entities
  # Specifies a product selection and its context.
  class ProductSelection < Dry::Struct
    transform_keys(&:to_sym)

    # @!attribute [r] enrollment 
    #   @return [HbxEnrollment] the enrollment the selection was
    #     performed against
    attribute :enrollment, ::Entities::Types.Nominal(HbxEnrollment)

    # @!attribute [r] product
    #   @return [BenefitMarkets::Products::Product] the selected product
    attribute :product, ::Entities::Types.Nominal(BenefitMarkets::Products::Product)

    # @!attribute [r] family
    #   @return [Family] the family involved
    attribute :family, ::Entities::Types.Nominal(Family)
  end
end