# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module BenefitSponsorship
      
      # Determines enrollment eligibility
      class DetermineEnrollmentEligibility
        # send(:include, Dry::Monads::Do.for(:call))
        send(:include, Dry::Monads[:result, :do])

        # @param [ Date ] effective_date Effective date of the benefit application
        # @param [ String ] sponsorship_id Benefit Sponsorship Id
        # @return [ BenefitSponsors::Entities::EnrollmentEligibility ] enrollment_eligibility
        def call(effective_date:, benefit_sponsorship_id:)
          effective_date                  = yield validate_effective_date(effective_date)
          benefit_sponsorship             = yield find_benefit_sponsorship(benefit_sponsorship_id)
          benefit_sponsorship_params      = yield build_benefit_sponsorship_params(benefit_sponsorship)
          benefit_sponsorship_values      = yield validate_benefit_sponsorship(benefit_sponsorship_params)
          benefit_sponsorship_entity      = yield create_benefit_sponsorship_entity(benefit_sponsorship_values)
          enrollment_eligibility_params   = yield build_enrollment_eligibility_params(effective_date, benefit_sponsorship_entity)
          enrollment_eligibility_entity   = yield create_enrollment_eligibility_entity(enrollment_eligibility_params)

          Success(enrollment_eligibility_entity)
        end

        private

        def validate_effective_date(effective_date)

          Success(effective_date)
        end

        def build_benefit_sponsorship_params(benefit_sponsorship)
          sponsorship_params = benefit_sponsorship.as_json.symbolize_keys.except(:benefit_applications)
          sponsorship_params[:benefit_applications] = benefit_sponsorship.benefit_applications.collect{|ba| ba.as_json.symbolize_keys.except(:benefit_packages)}
          Success(sponsorship_params)
        end

        def validate_benefit_sponsorship(benefit_sponsorship_params)
          result = BenefitSponsors::Validators::BenefitSponsorships::BenefitSponsorshipContract.new.call(benefit_sponsorship_params)

          if result.success?
            Success(result.to_h)
          else
            result.failure
          end
        end

        def build_enrollment_eligibility_params(effective_date, benefit_sponsorship_entity)
          eligibility_params = BenefitSponsors::Operations::EnrollmentEligibility::Determine.new.call(effective_date: effective_date, benefit_sponsorship: benefit_sponsorship_entity)

          if eligibility_params.success?
            Success(eligibility_params)
          else
            Failure(eligibility_params)
          end
        end

        def create_benefit_sponsorship_entity(benefit_sponsorship_values)
          benefit_sponsorship_entity = BenefitSponsors::Entities::BenefitSponsorship.new(benefit_sponsorship_values)

          Success(benefit_sponsorship_entity)
        end

        def create_enrollment_eligibility_entity(params)
          enrollment_eligibility_entity = BenefitSponsors::Operations::EnrollmentEligibility::Create.new.call(enrollment_eligibility_params: params.value!)

          Success(enrollment_eligibility_entity)
        end

        def find_benefit_sponsorship(benefit_sponsorship_id)
          result = BenefitSponsors::Operations::BenefitSponsorship::FindModel.new.call(benefit_sponsorship_id: benefit_sponsorship_id)

          if result.success?
            result
          else
            result.failure
          end
        end
      end
    end
  end
end