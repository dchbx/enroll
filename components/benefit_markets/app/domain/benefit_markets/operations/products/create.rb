# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module Products
      class Create
        send(:include, Dry::Monads[:result, :do])

        # @param [ Hash ] params Product Attributes
        # @return [ BenefitMarkets::Entities::Product ] product Product
        def call(product_params:)
          values   = yield validate(params)
          product  = yield create(values)
          
          Success(product)
        end

        private
  
        def validate(params)
          result = BenefitMarkets::Validators::Products::ProductContract.new.call(params)

          Success(result)
        end

        def create(values)
          product = BenefitMarkets::Entities::Product.new(values)

          Success(product)
        end
      end
    end
  end
end