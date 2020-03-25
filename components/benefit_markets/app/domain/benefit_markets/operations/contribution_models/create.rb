# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module ContributionModels

      class Create
        # include Dry::Monads::Do.for(:call)
        include Dry::Monads[:result, :do]

        # @param [ Hash ] params Benefit Sponsor Catalog attributes
        # @param [ Array<BenefitMarkets::Entities::ProductPackage> ] product_packages ProductPackage
        # @return [ BenefitMarkets::Entities::BenefitSponsorCatalog ] benefit_sponsor_catalog Benefit Sponsor Catalog
        def call(contribution_params:)
          contribution_values = yield validate(contribution_params)
          contribution_model  = yield create(contribution_values)
  
          Success(contribution_model)
        end

        private

        def validate(params)
          result = ::BenefitMarkets::Validators::ContributionModels::ContributionModelContract.new.call(params)

          if result.success?
            Success(result.to_h)
          else
            Failure("Unable to validate contribution model #{result.failure}")
          end
        end

        def create(values)
          contribution_model = ::BenefitMarkets::Entities::ContributionModel.new(values)

          Success(contribution_model)
        end
      end
    end
  end
end
