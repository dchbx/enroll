# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module ProductPackages
      class Renew
        include Dry::Monads[:result, :do]

        # @param [ Duration ] application_period Application Period of the Renewal Benefit Market Catalog
        # @param [ Hash ] existing_product_package_params Existing Product Package Params
        # @return [ BenefitMarkets::Entities::ProductPackage ] product_package Product Package
        def call(params)
          contributions   = yield renew_contribution_models(params)
          pricing_model   = yield renew_pricing_model(params)
          products        = yield renew_products(params)
          product_package = yield renew(params, contributions, pricing_model, products)

          Success(product_package)
        end

        private

        def renew_contribution_models(params)
          ::BenefitMarkets::Operations::ContributionModels::Renew.new.call(params)
        end

        def build_pricing_units_entities(params)
          params[:pricing_model][:pricing_units].collect do |pricing_unit_params|
            ::BenefitMarkets::Operations::PricingUnits::Create.new.call(pricing_unit_params: pricing_unit_params, package_kind: params[:package_kind]).value!
          end
        end

        def renew_pricing_model(params)
          params[:pricing_model][:pricing_units] = build_pricing_units_entities(params)
          ::BenefitMarkets::Operations::PricingModels::Create.new.call(params: params[:pricing_model])
        end

        def renew_products(params)
          ::BenefitMarkets::Operations::Products::Load.new.call(params)
        end

        def renew(params, contributions, pricing_model, products)
          params = params.slice(:benefit_kind, :product_kind, :description, :title, :package_kind, :application_period)
          params.merge!(contributions)
          params.merge!(pricing_model: pricing_model, products: products)

          ::BenefitMarkets::Operations::ProductPackages::Create.new.call(product_package_params: params, enrollment_eligibility: nil)
        end
      end
    end
  end
end
