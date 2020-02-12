# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module BenefitSponsorCatalog

      class Create
        # include Dry::Monads::Do.for(:call)
        include Dry::Monads[:result, :do]

        # @param [ Hash ] params Benefit Sponsor Catalog attributes
        # @param [ Array<BenefitMarkets::Entities::Product> ] products Product
        # @return [ BenefitMarkets::Entities::BenefitSponsorCatalog ] benefit_sponsor_catalog Benefit Sponsor Catalog
        def call(sponsor_catalog_params, product_packages)
          values = yield validate(sponsor_catalog_params)
          sponsor_catalog_values = yield assign_product_packages(values)
          product_packages = yield create(sponsor_catalog_values)
    
          Success(product_package_hash)
        end

        private

        def validate(params)
          values = BenefitMarkets::Validators::ProductPackageContract.new.call(params)

          Success(values)
        end

        def assign_product_packages(values, product_packages)
          values[:product_packages] = product_packages.collect(&:to_h)

          Success(values)
        end

        def create(sponsor_catalog_values)
          product_package = BenefitMarkets::Entities::BenefitSponsorCatalog.new(sponsor_catalog_values)
          
          Success(product_package)
        end
      end
    end
  end
end