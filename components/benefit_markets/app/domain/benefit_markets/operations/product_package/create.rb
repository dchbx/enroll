# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module ProductPackage

      class Create
        # include Dry::Monads::Do.for(:call)
        include Dry::Monads[:result, :do]

        # @param [ Hash ] params Product Package attributes
        # @param [ Array<BenefitMarkets::Entities::Product> ] products Product
        # @return [ BenefitMarkets::Entities::ProductPackage ] product_package Product Package
        def call(params, products)
          values                 = yield validate(params)
          product_package_values = yield assign_products(values)
          product_packages       = yield create(product_package_values)
    
          Success(product_package_hash)
        end

        private

        def validate(params)
          values = BenefitMarkets::Validators::Products::ProductPackageContract.new.call(params)

          Success(values)
        end

        def assign_products(values, products)
          values[:products] = products.collect(&:to_h)

          Success(values)
        end

        def create(product_package_values)
          product_package = BenefitMarkets::Entities::ProductPackage.new(product_package_values)
          
          Success(product_package)
        end
      end
    end
  end
end