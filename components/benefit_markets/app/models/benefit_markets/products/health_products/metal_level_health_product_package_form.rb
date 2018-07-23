module BenefitMarkets
  module Products
    module HealthProducts
      class MetalLevelHealthProductPackageForm < ::BenefitMarkets::Products::ProductPackageForm
        attr_accessor :metal_level

        validates_presence_of :metal_level, :allow_blank => false

        def has_additional_attributes?
          true
        end

        def additional_form_fields_partial
          "metal_level_health_additional_form_fields"
        end
      end

    end
  end
end
