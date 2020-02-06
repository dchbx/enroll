# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    include Dry::Monads[:result]
    include Dry::Monads::Do.for(:call)

    class CreateProductPackage

      # @param [ Date ] effective_date Effective date of the benefit application
      # @param [ Hash ] benefit_market_catalog Benefit Market Catalog for the given Effective Date
      # @param [ Array<BenefitMarkets::Entities::Locations::ServiceArea> ] benefit_market_catalog Benefit Market Catalog for the given Effective Date
      # @param [ Symbol ] market_kind Benefit Marketplace Type
      # @return [ BenefitMarkets::Entities::BenefitSponsorCatalog ] benefit_sponsor_catalog
      def call(params)
        values = yield validate(params)
        product_package_hash = extract_package_attributes(values)
        product_package_hash[:products] = yield filter_product_package_products(values)
  
        Success(product_package_hash)
      end

      private

      def extract_package_attributes(values)
        product_package_hash = values[:product_package].except(:products)
        product_package_hash[:application_period] = values[:application_period]
        product_package_hash
      end

      def filter_product_package_products(values)
        products = BenefitMarkets::Operations::BenefitMarketCatalog::ScopeProductsByServiceArea.new.call({
          effective_date: values[:effective_date], 
          market_kind: values[:market_kind], 
          package_kind: product_package[:package_kind],
          service_areas: values[:service_areas]
        })

        Success(products)
      end
    end
  end
end