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
          benefit_market = yield find_benefit_market(params)
          result = yield find_catalogs(benefit_market)

          Success(result)
        end

        private

        def find_benefit_market(params)
          ::BenefitMarkets::Operations::BenefitMarkets::FindModel.new.call(market_kind: params['market_kind'])
        end

        def find_catalogs(benefit_market)
          catalogs = benefit_market.benefit_market_catalogs
          calender_years = catalogs.sort{|a, b| b.application_period.min <=> a.application_period.min}.map(&:product_active_year)
          current_catalog = catalogs.by_application_date(TimeKeeper.date_of_record.prev_year).first
          
          Success([calender_years, current_catalog])
        end
      end
    end
  end
end