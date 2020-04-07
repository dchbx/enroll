# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module PricingUnits

      class Create
        # include Dry::Monads::Do.for(:call)
        include Dry::Monads[:result, :do]

        # @param [ pricing_unit_params ] params Contribution Unit attributes
        # @param [ sponsor_contribution_kind ] Type of sponsor contribution - fixed percent, fixed dollar, percent with cap
        # @return [ BenefitMarkets::Entities::PricingUnit ] pricing_unit entity
        def call(pricing_unit_params:, package_kind:)
          pricing_unit_type             = yield fetch_pricing_unit_kind(package_kind)
          validated_params              = yield validate(pricing_unit_params, pricing_unit_type)
          pricing_unit                  = yield create(validated_params, pricing_unit_type)

          Success(pricing_unit)
        end

        private

        def validate(params, type)
          pricing_unit_class = "::BenefitMarkets::Validators::PricingModels::#{type}Contract".constantize
          result = pricing_unit_class.new.call(params)

          if result.success?
            Success(result.to_h)
          else
            Failure("Unable to validate pricing unit due to #{result.errors}")
          end
        end

        def fetch_pricing_unit_kind(kind)
          pricing_unit_type =
            if kind == :single_product && Settings.site.key == :cca
              'TieredPricingUnit'
            else
              'RelationshipPricingUnit'
            end

          Success(pricing_unit_type)
        end

        def create(values, type)
          entity_class = "::BenefitMarkets::Entities::#{type}".constantize
          pricing_unit = entity_class.new(values)

          Success(pricing_unit)
        end
      end
    end
  end
end
