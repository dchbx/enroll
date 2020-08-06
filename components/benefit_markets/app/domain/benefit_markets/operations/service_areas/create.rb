# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module ServiceAreas
      class Create
        send(:include, Dry::Monads[:result, :do])

        # @param [ Hash ] params Service Area attributes
        # @return [ BenefitMarkets::Entities::ServiceArea ] service_area Service Area
        def call(service_area_params:)
          values       = yield validate(service_area_params)
          service_area = yield create(values)

          Success(service_area)
        end

        private

        def validate(params)
          result = ::BenefitMarkets::Validators::Locations::ServiceAreaContract.new.call(params)

          if result.success?
            Success(result)
          else
            Failure(result)
          end
        end

        def create(values)
          service_area = ::BenefitMarkets::Entities::ServiceArea.new(values.to_h)

          Success(service_area)
        end
      end
    end
  end
end