# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module BenefitMarketCatalogs
      class Configure
        include Dry::Monads[:result, :do]

        # @param [ Date ] effective_date Effective date of the benefit application
        # @param [ Symbol ] market_kind Benefit Market Catalog for the given Effective Date
        def call(params)
          values = yield validate(params)
          benefit_market = yield find_benefit_market(values)
          result = yield find_catalogs(benefit_market, values)

          Success(result)
        end

        private

        def validate(params)
          return Failure("Market kind must be provided") unless params['market_kind']
          params['effective_year'] = if params['effective_year']
            params['effective_year'].to_i
          else
            TimeKeeper.date_of_record.year
          end

          Success(params)
        end

        def find_benefit_market(values)
          ::BenefitMarkets::Operations::BenefitMarkets::FindModel.new.call(market_kind: values['market_kind'])
        end

        def find_catalogs(benefit_market, values)
          catalogs = benefit_market.benefit_market_catalogs
          calender_years = catalogs.sort{|a, b| b.application_period.min <=> a.application_period.min}.map(&:product_active_year)
          current_catalog = catalogs.by_application_date(Date.new(values['effective_year'],1,1)).first

          Success({
            calender_years: calender_years,
            catalog_year: values['effective_year'],
            record: current_catalog
          })
        end
      end
    end
  end
end