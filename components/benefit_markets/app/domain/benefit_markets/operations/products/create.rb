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
          values   = yield validate(product_params)
          product  = yield create(values.to_h)
          
          Success(product)
        end

        private
  
        def validate(params)
          contract = contract_class(params[:kind])
          result = contract.new.call(params)

          if result.success?
            Success(result.to_h)
          else
            Failure("Unable to validate product with hios_id #{params[:hios_id]}")
          end
        end

        def contract_class(product_kind)
          "::BenefitMarkets::Validators::Products::#{product_kind.to_s.camelize}ProductContract".constantize
        end

        def entity_class(product_kind)
          "::BenefitMarkets::Entities::#{product_kind.to_s.camelize}Product".constantize
        end

        def create(values)
          product = entity_class(values[:kind]).new(values)

          Success(product)
        end
      end
    end
  end
end