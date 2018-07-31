module BenefitMarkets
  module Products
    class ProductPackageFactory
      def self.build
        BenefitMarkets::Products::ProductPackage.new
      end

      def self.call(benefit_catalog:, benefit_kind:, title:, contribution_model:, pricing_model:, **other_params)
        benefit_catalog.product_packages.build benefit_kind: benefit_kind,
          application_period: benefit_catalog.application_period,
          title: title,
          contribution_model: contribution_model,
          pricing_model: pricing_model,
          **other_params
      end

      def self.validate(product_package)
        [
          is_contribution_model_satisfied?(product_package),
          is_pricing_model_satisfied?(product_package)
        ].all?
      end

      protected

      def self.is_pricing_model_satisfied?(product_package)
        pricing_model = product_package.pricing_model
        return true if pricing_model.nil?
        unless pricing_model.product_multiplicities.include?(product_package.product_multiplicity)
          product_package.errors.add(:pricing_model_id, "does not match the multiplicity of the product package")
          return false
        end
        true
      end

      def self.is_contribution_model_satisfied?(product_package)
        contribution_model = product_package.contribution_model
        return true if contribution_model.nil?
        unless contribution_model.product_multiplicities.include?(product_package.product_multiplicity)
          product_package.errors.add(:contribution_model_id, "does not match the multiplicity of the product package")
          return false
        end
        true
      end
    end
  end
end
