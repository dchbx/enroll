# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module ProductPackage
      # include Dry::Monads::Do.for(:call)

      class CreateProductPackage
        include Dry::Monads[:result, :do]

        # @param [ Date ] effective_date Effective date of the benefit application
        # @param [ Hash ] benefit_market_catalog Benefit Market Catalog for the given Effective Date
        # @param [ Array<BenefitMarkets::Entities::Locations::ServiceArea> ] benefit_market_catalog Benefit Market Catalog for the given Effective Date
        # @param [ Symbol ] market_kind Benefit Marketplace Type
        # @return [ BenefitMarkets::Entities::BenefitSponsorCatalog ] benefit_sponsor_catalog
        def call(params)
          values = yield validate(params)
          product_package_hash = extract_package_attributes(values)
          products_hash = yield filter_product_package_products(values)
          product_package_hash[:products] = products_hash.success
    
          Success(product_package_hash)
        end

        private

        def validate(params)
          # TODO: validate incoming params
          Success(params)
        end

        def extract_package_attributes(values)
          product_package_hash = values[:product_package].except(:products)
          product_package_hash[:application_period] = values[:product_package][:application_period]
          product_package_hash
        end

        def filter_product_package_products(values)
          products = BenefitMarkets::Operations::ProductPackage::ScopeProductsByServiceAreas.new.call({
            effective_date: values[:effective_date], 
            market_kind: values[:market_kind], 
            package_kind: values[:product_package][:package_kind],
            service_areas: values[:service_areas]
          })

          Success(products)
        end
      end
    end
  end
end