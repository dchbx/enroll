# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module BenefitMarketCatalog
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class Find

        # @param [ Date ] effective_date Effective date of the benefit application
        # @param [ Symbol ] market_kind Benefit Market Catalog for the given Effective Date
        def call(params)
          benefit_market_catalog =  yield benefit_market_catalog(params)
          
          Success(benefit_market_catalog)
        end

        private
        
        def benefit_market_catalog(params)
          benefit_market = benefit_market(params)
          benefit_market_catalog = benefit_market.benefit_market_catalog_for(params[:effective_date])
          
          Success(benefit_market_catalog)
        end

        def benefit_market(params)
          return @benefit_market if defined? @benefit_market
          @benefit_market = BenefitMarkets::Operations::BenefitMarket::Find.new.call(market_kind: params[:market_kind])
        end
      end
    end
  end
end