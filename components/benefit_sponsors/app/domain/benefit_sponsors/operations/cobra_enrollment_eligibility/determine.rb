# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module CobraEnrollmentEligibility
      # Determines cobra enrollment eligibility
      class Determine
        send(:include, Dry::Monads[:result, :do])

        # @param [ Date ] effective_date Effective date of the benefit application
        # @param [ Benefit Application id ] benefit_application_id
        # @return [ enrollment_eligibility_hash ] enrollment_eligibility_hash
        def call(effective_date:, benefit_application_id:)
          effective_date             = yield validate_effective_date(effective_date)
          application_type           = yield find_application_type(benefit_application_id)
          eligibility_params         = yield eligibility(effective_date, application_type)

          Success(eligibility_params)
        end

        private

        def validate_effective_date(effective_date)
          Success(effective_date)
        end

        def find_application_type(benefit_application_id)
          benefit_application = BenefitSponsors::Operations::BenefitApplication::FindModel.new.call(benefit_application_id: benefit_application_id).success
          type = benefit_application.is_renewing? ? 'renewal' : 'initial'

          Success("#{type}_sponsor")
        end

        def eligibility(effective_date, application_type)
          if ::EnrollRegistry.feature_enabled?("cobra_eligibility_criterion_#{effective_date.year}")
            cobra_eligibility_range = ::EnrollRegistry["cobra_eligibility_criterion_#{effective_date.year}"].setting(application_type).item

            Success(cobra_eligibility_range.cover?(effective_date))
          else
            Success(false)
          end
        end
      end
    end
  end
end