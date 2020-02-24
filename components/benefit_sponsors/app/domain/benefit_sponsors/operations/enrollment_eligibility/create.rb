# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSposnors
  module Operations
    module EnrollmentEligibility
      
      # Determines enrollment eligibility
      class Create
        # send(:include, Dry::Monads::Do.for(:call))
        send(:include, Dry::Monads[:result, :do])

        # @param [ Date ] effective_date Effective date of the benefit application
        # @param [ BenefitSponsors::Entities::BenefitSponsorship ] benefit_sponsorship Benefit Sponsorship Entity
        # @return [ BenefitSponsors::Entities::EnrollmentEligibility ] enrollment_eligibility
        def call(effective_date:, benefit_sponsorship:)
          effective_date             = yield validate_effective_date(effective_date)
          eligibility                = yield create(effective_date, benefit_sponsorship)

          Success(eligibility)
        end

        private

        def validate_effective_date(effective_date)

          Success(effective_date)
        end

        def create(effective_date, benefit_sponsorship)
          overlapping_application = benefit_sponsorship.benefit_applications.any?{|application| application.effective_period.cover?(effective_date)}
          enrollment_kind ||= :initial
        
          Success(benefit_sponsor_catalog)
        end
      end
    end
  end
end