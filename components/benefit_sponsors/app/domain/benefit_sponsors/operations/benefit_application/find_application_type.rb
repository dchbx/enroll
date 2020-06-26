# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module BenefitApplication
      class FindApplicationType
        include Dry::Monads[:result, :do]

        # @param  [ String ] benefit_application_id Benefit Application id
        # @return [ Boolean ] true/false

        def call(benefit_application_id:)
          application_type = yield application_type(benefit_application_id)

          Success(application_type)
        end

        private

        def application_type(benefit_application_id)
          benefit_application = find_benefit_application(benefit_application_id)
          type = benefit_application.is_renewing? ? 'renewal' : 'initial'

          Success(type)
        end

        def find_benefit_application(benefit_application_id)
          result = BenefitSponsors::Operations::BenefitApplication::FindModel.new.call(benefit_application_id: benefit_application_id)
          if result.success?
            result.value!
          else
            result.failure
          end
        end
      end
    end
  end
end