# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module ProductPackage
      class ScopeProductsByServiceAreas
        include Dry::Monads[:result, :do]

        # @param [ Date ] effective_date Effective date of the benefit application
        # @param [ Symbol ] market_kind Benefit Market Catalog for the given Effective Date
        # @param [ Symbol ] package_kind PackageKind
        # @param [ Array<BenefitMarkets::Entities::Locations::ServiceArea> ] service areas by benefit sponsor location
        def call(params)
          @params = params

          products = yield filter_products_by_service_areas(params[:service_areas])
          Success(products)
        end

        private

        def filter_products_by_service_areas(service_areas)
          products = product_package.all_benefit_market_products
          products_by_service_areas = products.by_service_areas(service_areas.map(&:id))
          products_hash = products_by_service_areas.effective_with_premiums_on(@params[:effective_date]).collect{|product|
            product_hash = product.as_json.deep_symbolize_keys.except(:premium_tables)
            product_hash[:premium_tables] = product.as_json.deep_symbolize_keys[:premium_tables].collect{|pt| pt.except(:premium_tuples)}
            product_hash
          }
          Success(products_hash)
        end

        def product_package
          return @product_package if defined? @product_package
          @product_package = benefit_market_catalog.product_packages.by_package_kind(@params[:package_kind]).first
        end

        def benefit_market_catalog
          return @benefit_market_catalog if defined? @benefit_market_catalog
          @benefit_market_catalog = BenefitMarketCatalog::Find.new.call(effective_date: @params[:effective_date], market_kind: @params[:market_kind]).success
        end
      end
    end
  end
end
  