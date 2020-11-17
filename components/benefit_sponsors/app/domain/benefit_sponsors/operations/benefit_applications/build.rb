# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module BenefitApplications
      class Build
        include Dry::Monads[:result, :do]

        # @param [ Hash ] benefit_application attributes
        # @return [ BenefitSponsors::Entities::BenefitApplication ] benefit_application
        def call(params)
          values = yield validate(params)
          entity = yield initialize_entity(values)

          Success(entity)
        end

        private

        def validate(params)
          contract_result = ::BenefitSponsors::Validators::BenefitApplications::BenefitApplicationContract.new.call(params)
          contract_result.success? ? Success(contract_result.to_h) : Failure(contract_result.errors)
        end

        def initialize_entity(values)
          Success(::BenefitSponsors::Entities::BenefitApplication.new(values.to_h))
        end
      end
    end
  end
end
