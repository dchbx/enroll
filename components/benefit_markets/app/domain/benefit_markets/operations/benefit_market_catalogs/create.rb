# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module BenefitMarketCatalogs
      class Create
        # include Dry::Monads::Do.for(:call)
        include Dry::Monads[:result, :do]

        # @param [ Hash ] params Benefit Sponsor Catalog attributes
        # @param [ Array<BenefitMarkets::Entities::ProductPackage> ] product_packages ProductPackage
        # @return [ BenefitMarkets::Entities::BenefitMarketCatalog ] benefit_market_catalog Benefit Sponsor Catalog
        def call(market_catalog_params)
          market_catalog_values  = yield validate(market_catalog_params)
          benefit_market_catalog = yield create(market_catalog_values)

          Success(benefit_market_catalog)
        end

        private

        def validate(market_catalog_params)
          result = ::BenefitMarkets::Validators::BenefitMarketCatalogs::BenefitMarketCatalogContract.new.call(market_catalog_params)

          if result.success?
            Success(result.to_h)
          else
            Failure(result.errors.to_h)
          end
        end

        def create(market_catalog_values)
          benefit_market_catalog = ::BenefitMarkets::Entities::BenefitMarketCatalog.new(market_catalog_values)

          Success(benefit_market_catalog)
        end
      end
    end
  end
end