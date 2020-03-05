# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module EnrollmentEligibility
      # Determines enrollment eligibility
      class Determine
        send(:include, Dry::Monads[:result, :do])

        # @param [ Date ] effective_date Effective date of the benefit application
        # @param [ BenefitSponsors::Entities::BenefitSponsorship ] benefit_sponsorship Benefit Sponsorship Entity
        # @return [ enrollment_eligibility_hash ] enrollment_eligibility_hash
        def call(effective_date:, benefit_sponsorship:)
          effective_date             = yield validate_effective_date(effective_date)
          eligibility_params         = yield eligibility_params(effective_date, benefit_sponsorship)

          Success(eligibility_params)
        end

        private

        def validate_effective_date(effective_date)
          Success(effective_date)
        end

        def application_type(effective_date, benefit_sponsorship)
          benefit_applications = benefit_sponsorship.benefit_applications
          if is_renewing_sponsor?(benefit_applications, effective_date)
            'renewing'
          elsif is_initial_sponsor?(benefit_applications, effective_date)
            'initial'
          end
        end

        def eligibility_params(effective_date, benefit_sponsorship)
          params = {
            benefit_sponsorship_id: benefit_sponsorship._id,
            effective_date: effective_date,
            application_type: application_type(effective_date, benefit_sponsorship)
          }

          Success(params)
        end

        def is_initial_sponsor?(benefit_applications, effective_date)
          recent_benefit_application = benefit_applications.max_by(&:effective_period)
          return true unless recent_benefit_application

          return true if recent_benefit_application.aasm_state == :active && recent_benefit_application.effective_period.cover?(effective_date)

          ba_states = BenefitSponsors::BenefitApplications::BenefitApplication::RENEWAL_TRANSMISSION_STATES +
                      BenefitSponsors::BenefitApplications::BenefitApplication::CANCELED_STATES
          effective_date.to_date > recent_benefit_application.effective_period.max.next_day.to_date || ba_states.include?(recent_benefit_application.aasm_state)
        end

        def is_renewing_sponsor?(benefit_applications, effective_date)
          active_benefit_application = benefit_applications.detect { |benefit_application| benefit_application.aasm_state == :active }
          return false unless active_benefit_application

          effective_date.to_date == active_benefit_application.effective_period.max.next_day.to_date
        end
      end
    end
  end
end