# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module EnrollmentEligibility
      # Creates enrollment eligibility entity
      class Create
        send(:include, Dry::Monads[:result, :do])

        # @param  [ enrollment_eligibility_params ] enrollment_eligibility_params
        # @return [ BenefitSponsors::Entities::EnrollmentEligibility ] enrollment_eligibility
        def call(enrollment_eligibility_params:)
          params                     = yield validate_params(enrollment_eligibility_params)
          eligibility                = yield create(params)

          Success(eligibility)
        end

        private

        def validate_params(params)
          enrollment_eligibility = BenefitSponsors::Validators::EnrollmentEligibilityContract.new.call(params)

          if enrollment_eligibility.success?
            Success(enrollment_eligibility.to_h)
          else
            Failure(enrollment_eligibility)
          end
        end

        def create(params)
          enrollment_eligibility_entity = BenefitSponsors::Entities::EnrollmentEligibility.new(params)

          Success(enrollment_eligibility_entity)
        end
      end
    end
  end
end