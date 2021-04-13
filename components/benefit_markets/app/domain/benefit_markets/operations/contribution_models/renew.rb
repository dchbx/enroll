# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module ContributionModels
      class Renew
        # include Dry::Monads::Do.for(:call)
        include Dry::Monads[:result, :do]

        # @param [ Hash ] params Benefit Sponsor Catalog attributes
        # @return [ Array<BenefitMarkets::Entities::ContributionModel> ] contribution_models ContributionModel
        def call(params)
          params = yield extract(params)
          values = yield renew(params)

          Success(values)
        end

        private

        # TODO: Update key and title to Simple List Bill Contribution Model
        #       PercentWithCapContributionModel
        def extract(params)
          contribution_params = {
            contribution_models: params[:contribution_models],
            contribution_model: params[:contribution_model]
          }

          Success(contribution_params)
        end

        def renew(contribution_params)
          data = {}

          data[:contribution_models] = contribution_params[:contribution_models]&.collect {|params| build_entity(params)}
          data[:contribution_model]  = build_entity(contribution_params[:contribution_model]) if contribution_params[:contribution_model].present?

          Success(data)
        rescue StandardError => e
          Failure(e)
        end

        def build_entity(params)
          contribution_model = ::BenefitMarkets::Operations::ContributionModels::Create.new.call(contribution_params: params)
          raise StandardError, contribution_model.failure.errors if contribution_model.failure?
          contribution_model.value!
        end
      end
    end
  end
end
