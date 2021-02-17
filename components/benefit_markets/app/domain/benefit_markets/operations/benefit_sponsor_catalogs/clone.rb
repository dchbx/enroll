# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module BenefitSponsorCatalogs
      # This class clones a benefit_sponsor_catalog where end
      # result is a new benefit_sponsor_catalog. Also, the result
      # benefit_sponsor_catalog is a non-persisted object
      # without benefit_application.
      class Clone
        include Dry::Monads[:result, :do]

        # @param [ BenefitMarkets::BenefitSponsorCatalog ] benefit_sponsor_catalog
        # @return [ BenefitMarkets::BenefitSponsorCatalog ] benefit_sponsor_catalog
        def call(params)
          values                  = yield validate(params)
          bsc_params              = yield construct_params(values)
          bsc_entity              = yield create_benefit_sponsor_catalog(bsc_params)
          benefit_sponsor_catalog = yield init_benefit_sponsor_catalog(bsc_entity)

          Success(benefit_sponsor_catalog)
        end

        private

        def validate(params)
          return Failure('Missing Key.') unless params.key?(:benefit_sponsor_catalog)
          return Failure('Not a valid BenefitSponsorCatalog object.') unless params[:benefit_sponsor_catalog].is_a?(::BenefitMarkets::BenefitSponsorCatalog)

          Success(params)
        end

        def create_benefit_sponsor_catalog(bsc_params)
          Create.new.call({sponsor_catalog_params: bsc_params})
        end

        def init_benefit_sponsor_catalog(bsc_entity)
          Success(::BenefitMarkets::BenefitSponsorCatalog.new(bsc_entity.to_h))
        end

        def construct_params(values)
          Success(values[:benefit_sponsor_catalog].serializable_hash.deep_symbolize_keys)
        end
      end
    end
  end
end
