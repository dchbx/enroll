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
        def call(sponsor_catalog_params:)
          sponsor_catalog_values  = yield validate(sponsor_catalog_params)
          benefit_sponsor_catalog = yield create(sponsor_catalog_values)
    
          Success(benefit_sponsor_catalog)
        end

        private

        def validate(sponsor_catalog_params)
          result = ::BenefitMarkets::Validators::BenefitSponsorCatalogs::BenefitSponsorCatalogContract.new.call(sponsor_catalog_params)

          if result.success?
            Success(result.to_h)
          else
            Failure(result.errors)
          end
        end

        def create(sponsor_catalog_values)
          sponsor_catalog_params = sponsor_catalog_values.to_h
          sponsor_catalog_params[:product_packages].each do |package_param|
            product_entities = package_param[:products].inject([]) do |products_array, product_param|
              products_array << init_product_entity(product_param)
            end
            package_param.to_h[:products] = product_entities
          end
          benefit_sponsor_catalog = ::BenefitMarkets::Entities::BenefitSponsorCatalog.new(sponsor_catalog_params)
          Success(benefit_sponsor_catalog)
        end

        def init_product_entity(product_param)
          entity_class = if product_param[:kind].present? && [:health, :dental].include?(product_param[:kind])
                           "BenefitMarkets::Entities::#{product_param[:kind].to_s.camelize}Product".constantize
                         else
                           ::BenefitMarkets::Entities::Product
                         end
          entity_class.new(product_param)
        end
      end
    end
  end
end