# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module ProductPackages

      class Create
        # include Dry::Monads::Do.for(:call)
        include Dry::Monads[:result, :do]

        # @param [ Hash ] params Product Package attributes
        # @param [ Array<BenefitMarkets::Entities::Product> ] products Product
        # @return [ BenefitMarkets::Entities::ProductPackage ] product_package Product Package
        def call(product_package_params:, products:)
          values                 = yield validate(product_package_params)
          product_package        = yield create(values.to_h, products)
    
          Success(product_package)
        end

        private

        def validate(product_package_params)
          result = ::BenefitMarkets::Validators::Products::ProductPackageContract.new.call(product_package_params)

          if result.success?
            Success(result)
          else
            Failure(result.errors.to_h)
          end
        end

        def create(product_package_values, products)
          product_package = ::BenefitMarkets::Entities::ProductPackage.new(product_package_values.merge(products: products))
          
          Success(product_package)
        end
      end
    end
  end
end