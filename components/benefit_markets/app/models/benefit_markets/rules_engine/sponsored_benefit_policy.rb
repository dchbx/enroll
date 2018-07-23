module BenefitMarkets
  module RulesEngine
    class SponsoredBenefitPolicy < Policy
      rule :metal_level_selected, 
        validate: lambda { |c| !c.get(:product_package).metal_level.blank? },
        failure: lambda { |c| c.get(:product_package).errors.add(:metal_level, "must have a metal level selected") },
        requires: [:product_package]

      rule :reference_product_selected,
        validate: lambda { |c| !c.get(:product_package).reference_product.blank? }

      rule :carrier_selected

      rule :single_plan_selected

      rule :sole_source_package_satisfied, :all_of => [:single_plan_selected],
        applicable_if: lambda { |c| c.get(:product_package).is_sole_source_package? }

      rule :metal_level_package_satisfied, :all_of => [:metal_level_selected, :reference_product_selected],
        applicable_if: lambda { |c| c.get(:product_package).is_metal_level_package? }

      rule :carrier_package_satisfied, :all_of => [:carrier_selected, :reference_plan_selected],
        applicable_if: lambda { |c| c.get(:product_package).is_carrier_package? }

      rule :package_creation_complete, :any_of => [:metal_level_package_satisfied, :sole_source_package_satisfied, :carrier_package_satisfied],
        success: lambda { |c| c.succeed! },
        failure: lambda { |c| c.fail! }

      def self.call(product_package)
        context = PolicyExecutionContext.new(product_package: product_package)
        self.new.evaluate(context)
        context
      end
    end
  end
end
