module BenefitMarkets
  module Products
    module HealthProducts
      class IssuerHealthProductPackageForm < ::BenefitMarkets::Products::ProductPackageForm
        attr_accessor :issuer_id

        validates_presence_of :issuer_id, :allow_blank => false

        def has_additional_attributes?
          true
        end

        def additional_form_fields_partial
          "issuer_health_additional_form_fields"
        end
      end
    end
  end
end
