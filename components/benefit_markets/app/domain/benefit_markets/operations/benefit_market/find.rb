# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module BenefitMarket
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class Find

        # @param [ Symbol ] market_kind Benefit Market Catalog for the given Effective Date
        def call(params)
          benefit_market = yield benefit_market(params[:market_kind])          
          
          Success(benefit_market)
        end

        private
        
        def benefit_market(market_kind)
          benefit_market = BenefitMarkets::BenefitMarket.find_by_kind(market_kind)

          Success(benefit_market)
        end
      end
    end
  end
end