# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module Products
      class Load
        send(:include, Dry::Monads[:result, :do])

        # @param [ Hash ] params Product Attributes
        # @return [ Array<BenefitMarkets::Entities::Product> ] products Product
        def call(params)
          params = yield fetch(params)
          values = yield renew(params)

          Success(values)
        end

        private

        def fetch(params)
          p_candidate = OpenStruct.new(params.slice(:benefit_kind, :product_kind, :package_kind, :application_period))
          products_params = ::BenefitMarkets::Products::Product.by_product_package(p_candidate).collect{|product| product.create_copy_for_embedding.serializable_hash }

          Success(products_params)
        end

        def renew(products_params)
          products = products_params.collect do |product_params|
            product = ::BenefitMarkets::Operations::Products::Create.new.call(product_params: product_params.symbolize_keys)
            raise StandardError, product.failure.errors if product.failure?
            product.value!
          end

          Success(products)
        rescue StandardError => e
          Failure(e)
        end
      end
    end
  end
end