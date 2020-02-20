# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSposnors
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
          effective_date             = yield validate_effective_date(effective_date)
          benefit_sponsorship        = yield find_benefit_sponsorship(benefit_sponsorship_id)
          benefit_sponsorship_params = yield build_benefit_sponsorship(benefit_sponsorship)
          benefit_sponsorship_values = yield validate_benefit_sponsorship(benefit_sponsorship_params)
          benefit_sponsorship_entity = yield create_benefit_sponsorship_entity(benefit_sponsorship_values)
          enrollment_eligibility     = yield determine_eligibility(effective_date, benefit_sponsorship_entity)

          Success(enrollment_eligibility)
        end

        private

        def validate_effective_date(effective_date)

          Success(effective_date)
        end

        def build_benefit_sponsorship(benefit_sponsorship)
          sponsorship_params = benefit_sponsorship.attributes.except(:benefit_applications)
          sponsorship_params[:benefit_applications] = benefit_sponsorship.benefit_applications.collect{|ba| ba.attributes.except(:benefit_packages)}
          Success(sponsorship_params)
        end

        def validate_benefit_sponsorship(benefit_sponsorship_params)
          result = BenefitSponsors::Validators::BenefitSponsorshipContract.new.call(benefit_sponsorship_params)

          Success(result)
        end

        def create_benefit_sponsorship_entity(benefit_sponsorship_values)
          benefit_sponsorship_entity = BenefitSponsors::Entities::BenefitSponsorship.new(benefit_sponsorship_values)

          Success(benefit_sponsorship_entity)
        end

        def determine_eligibility(effective_date, benefit_sponsorship_entity)
          enrollment_eligibility = BenefitMarkets::Operations::EnrollmentEligibility::Create.new.call(effective_date: effective_date, benefit_sponsorship: benefit_sponsorship_entity)
        
          Success(enrollment_eligibility)
        end

        def find_benefit_sponsorship(benefit_sponsorship_Id)
          benefit_sponsorship = BenefitSponsors::Operations::BenefitSponsorship::Find.new.call(benefit_sponsorship_id)

          Success(benefit_sponsorship)
        end
      end
    end
  end
end