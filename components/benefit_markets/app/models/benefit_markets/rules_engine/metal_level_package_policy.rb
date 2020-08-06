# frozen_string_literal: true

module BenefitMarkets
  module RulesEngine
    class MetalLevelPackagePolicy < Policy

      rule :metal_level_selected,
           validate: ->(c) { !c.get(:product_package).metal_level.blank? },
           failure: ->(c) { c.add_error(:product_package, "must have a metal level selected") },
           requires: [:product_package]

      def self.call(product_package)
        context = PolicyExecutionContext.new(product_package: product_package)
        self.new.evaluate(context)
        context
      end


    end
  end
end
