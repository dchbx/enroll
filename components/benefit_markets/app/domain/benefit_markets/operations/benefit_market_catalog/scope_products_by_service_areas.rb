# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module BenefitMarketCatalog
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class ScopeProductsByServiceAreas

        # @param [ Date ] effective_date Effective date of the benefit application
        # @param [ Symbol ] market_kind Benefit Market Catalog for the given Effective Date
        def call(params)
          @params = params

          products = yield filter_products_by_service_areas(params[:service_areas])
        end

        private

        def filter_products_by_service_areas(service_areas)

          Success(products)
        end

        def product_package
          return @product_package if defined? @product_package
          @product_package = benefit_market_catalog.product_packages.by_package_kind(@params[:package_kind])
        end

        def benefit_market_catalog
          return @benefit_market_catalog if defined? @benefit_market_catalog
          @benefit_market_catalog = Find.new.call(effective_date: @params[:effective_date], market_kind: @params[:market_kind])          
        end
      end
    end
  end
end
  