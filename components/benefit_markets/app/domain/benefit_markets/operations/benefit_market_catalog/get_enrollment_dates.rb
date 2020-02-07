# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module BenefitMarketCatalog
      # include Dry::Monads[:result]
      # include Dry::Monads::Do.for(:call)

      class GetEnrollmentDates
        include Dry::Monads[:result, :do]

        # @param [ Date ] effective_date Effective date of the benefit application
        # @param [ Symbol ] market_kind Benefit Market Catalog for the given Effective Date
        def call(params)
          @params = params

          effective_period       = yield get_effective_period(params[:effective_date])
          open_enrollment_period = yield get_open_enrollment_period(params[:effective_date])

          Success({
            enrollment_dates: {
              effective_period: effective_period, 
              open_enrollment_period: open_enrollment_period
            }
          })
        end

        private 

        def get_effective_period(effective_date)
          Success(benefit_market_catalog.effective_period_on(effective_date))
        end

        def get_open_enrollment_period(effective_date)
          Success(benefit_market_catalog.open_enrollment_period_on(effective_date))
        end

        def benefit_market_catalog
          return @benefit_market_catalog if defined? @benefit_market_catalog
          @benefit_market_catalog = BenefitMarketCatalog::Find.new.call(@params).success
        end
      end
    end
  end
end
  