# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module BenefitMarkets
      # include Dry::Monads::Do.for(:call)
      class FindModel
        include Dry::Monads[:result, :do]

        # @param [ Symbol ] market_kind Benefit Market Catalog for the given Effective Date
        def call(params)
          benefit_market = yield benefit_market(params[:market_kind])

          Success(benefit_market)
        end

        private

        def benefit_market(market_kind)
          benefit_market = ::BenefitMarkets::BenefitMarket.by_market_kind(market_kind).first

          Success(benefit_market)
        end
      end
    end
  end
end