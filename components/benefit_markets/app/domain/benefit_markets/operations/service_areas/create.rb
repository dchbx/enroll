# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module ServiceArea
      class Create
        send(:include, Dry::Monads[:result, :do])

        # @param [ Hash ] params Service Area attributes
        # @return [ BenefitMarkets::Entities::ServiceArea ] service_area Service Area
        def call(params:)
          values       = yield validate(params)
          service_area = yield create(values)
          
          Success(service_area)
        end

        private
  
        def validate(params)
          result = BenefitMarkets::Validators::ServiceAreas::ServiceAreaContract.new.call(params)

          Success(result)
        end

        def create(values)
          service_area = BenefitMarkets::Entities::ServiceArea.new(values)

          Success(service_area)
        end
      end
    end
  end
end