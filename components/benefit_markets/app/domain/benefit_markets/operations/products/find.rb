# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module Products
      class Find
        send(:include, Dry::Monads[:result, :do])

        # @param [ Date ] effective_date Effective date of the benefit application in rfc3339 date format
        # @param [ Array<BenefitMarkets::Entities::ServiceArea> ] service_areas Service Areas
        # @param [ BenefitMarkets::Products::ProductPackage ] product_package Product Package
        # @return [ Array<BenefitMarkets::Entities::Product> ] products Products
        def call(effective_date:, service_areas:, product_package:)
          effective_date     = yield validate_effective_date(effective_date)
          products_params    = yield scope_products(effective_date, service_areas, product_package)
          products           = yield create_products(products_params)
          Success(products)
        end

        private 

        # date type check
        def validate_effective_date(effective_date)
          
          Success(effective_date)
        end

        # TODO: Refactor not to depend on product_package model
        def scope_products(effective_date, service_areas, product_package)
          product_params = ::BenefitMarkets::Products::Product.by_product_package(product_package)
                                                              .by_service_areas(service_areas.map(&:_id))
                                                              .effective_with_premiums_on(effective_date)
                                                              .collect{|product| product.create_copy_for_embedding.as_json.deep_symbolize_keys}

          Success(product_params)
        end

        def create_products(products_params)
          products = products_params.collect do |params|
            ::BenefitMarkets::Operations::Products::Create.new.call(product_params: params).value!
          end

          Success(products)
        end
      end
    end
  end
end