# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module PricingModels

      class Create
        # include Dry::Monads::Do.for(:call)
        include Dry::Monads[:result, :do]

        # @param [ Hash ] params Benefit Sponsor Catalog attributes
        # @param [ Array<BenefitMarkets::Entities::ProductPackage> ] product_packages ProductPackage
        # @return [ BenefitMarkets::Entities::BenefitSponsorCatalog ] benefit_sponsor_catalog Benefit Sponsor Catalog
        def call(params:)
          values = yield validate(params)
          pricing_model = yield create(values)
  
          Success(pricing_model)
        end

        private

        def validate(params)
          result = ::BenefitMarkets::Validators::PricingModels::PricingModelContract.new.call(params)

          if result.success?
            Success(result.to_h)
          else
            Failure("Unable to validate pricing model #{result.errors.to_h}")
          end
        end

        def create(values)
          contribution_model = ::BenefitMarkets::Entities::PricingModel.new(values)

          Success(contribution_model)
        end
      end
    end
  end
end
