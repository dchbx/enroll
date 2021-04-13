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
          contribution_units_values = yield contribution_unit_models_for(contribution_values)
          contribution_model = yield create(contribution_values, contribution_units_values)
  
          Success(contribution_model)
        end

        private

        def validate(params)
          result = ::BenefitMarkets::Validators::ContributionModels::ContributionModelContract.new.call(params)

          if result.success?
            Success(result.to_h)
          else
            Failure("Unable to validate contribution model #{result.errors.to_h}")
          end
        end

        def contribution_unit_models_for(contribution_model_params)
          sponsor_contribution_kind = contribution_model_params[:sponsor_contribution_kind]
          contribution_units = contribution_model_params[:contribution_units].collect do |contribution_unit_params|
            result = ::BenefitMarkets::Operations::ContributionUnits::Create.new.call(contribution_unit_params: contribution_unit_params, sponsor_contribution_kind: sponsor_contribution_kind)
            raise StandardError, result.failure if result.failure?
            result.value!
          end
          Success(contribution_units)
        rescue StandardError => e
          Failure(e)
        end

        def create(values, contribution_units_values)
          values[:contribution_units] = contribution_units_values
          contribution_model = ::BenefitMarkets::Entities::ContributionModel.new(values)

          Success(contribution_model)
        end
      end
    end
  end
end
