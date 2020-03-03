# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module BenefitSponsorCatalogs

      class Create
        # include Dry::Monads::Do.for(:call)
        include Dry::Monads[:result, :do]

        # @param [ Hash ] params Benefit Sponsor Catalog attributes
        # @param [ Array<BenefitMarkets::Entities::ProductPackage> ] product_packages ProductPackage
        # @return [ BenefitMarkets::Entities::BenefitSponsorCatalog ] benefit_sponsor_catalog Benefit Sponsor Catalog
        def call(sponsor_catalog_params:, product_packages:)
          sponsor_catalog_values  = yield validate(sponsor_catalog_params, product_packages)
          benefit_sponsor_catalog = yield create(sponsor_catalog_values.to_h, product_packages)
    
          Success(benefit_sponsor_catalog)
        end

        private

        def validate(sponsor_catalog_params, product_packages)
          contract_params = sponsor_catalog_params.merge(product_packages: product_packages.collect(&:to_h))
          result = ::BenefitMarkets::Validators::BenefitSponsorCatalogContract.new.call(contract_params)

          if result.success?
            Success(result)
          else
            Failure(result.errors)
          end
        end

        def create(sponsor_catalog_values, product_packages)
          contract_params = sponsor_catalog_values.merge(product_packages: product_packages)
          benefit_sponsor_catalog = ::BenefitMarkets::Entities::BenefitSponsorCatalog.new(contract_params)
          
          Success(benefit_sponsor_catalog)
        end
      end
    end
  end
end