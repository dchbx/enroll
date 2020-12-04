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
          service_areas_entities     = yield get_service_areas_entities(effective_date, benefit_sponsorship)
          eligibility_params         = yield eligibility_params(effective_date, benefit_sponsorship, service_areas_entities)

          Success(eligibility_params)
        end

        private

        def validate_effective_date(effective_date)
          Success(effective_date)
        end

        def application_type(effective_date, benefit_sponsorship)
          benefit_applications = benefit_sponsorship.benefit_applications
          if is_renewing_sponsor?(benefit_applications, effective_date)
            'renewal'
          elsif is_initial_sponsor?(benefit_applications, effective_date)
            'initial'
          end
        end

        def eligibility_params(effective_date, benefit_sponsorship, service_areas_entities)
          params = {
            market_kind: benefit_sponsorship.market_kind,
            benefit_sponsorship_id: benefit_sponsorship._id,
            effective_date: effective_date,
            benefit_application_kind: application_type(effective_date, benefit_sponsorship),
            service_areas: service_areas_entities.as_json
          }

          Success(params)
        end

        def get_service_areas_entities(effective_date, benefit_sponsorship_entity)
          benefit_sponsorship = find_benefit_sponsorship(benefit_sponsorship_entity._id)
          service_areas = benefit_sponsorship.service_areas_on(effective_date).collect do |service_area|
            result = BenefitMarkets::Operations::ServiceAreas::Create.new.call(service_area_params: service_area.as_json)
            if result.success?
              result.value!
            else
              nil
            end
          end.compact

          Success(service_areas)
        end

        def find_benefit_sponsorship(benefit_sponsorship_entity_id)
          result = BenefitSponsors::Operations::BenefitSponsorship::FindModel.new.call(benefit_sponsorship_id: benefit_sponsorship_entity_id)
          if result.success?
            result.value!
          else
            result.failure
          end
        end

        def is_initial_sponsor?(benefit_applications, effective_date)
          recent_benefit_application = benefit_applications.sort { |a, b|  a.effective_period.min <=> b.effective_period.min }.last
          return true unless recent_benefit_application
          return true if recent_benefit_application.is_termed_or_ineligible? || recent_benefit_application.aasm_state == :active && recent_benefit_application.effective_period.cover?(effective_date)

          ba_states = BenefitSponsors::BenefitApplications::BenefitApplication::RENEWAL_TRANSMISSION_STATES +
                      BenefitSponsors::BenefitApplications::BenefitApplication::CANCELED_STATES +
                      BenefitSponsors::BenefitApplications::BenefitApplication::EXPIRED_STATES
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