# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module BenefitSponsorCatalog
      # Build BenefitSponsorCatalog entity
      class Build
        send(:include, Dry::Monads[:result, :do])

        # @param [ Date ] effective_date Effective date of the benefit application
        # @param [ String ] sponsorship_id Benefit Sponsorship Id
        # @return [ BenefitSponsors::Entities::EnrollmentEligibility ] enrollment_eligibility
        def call(effective_date:, benefit_sponsorship_id:)
          effective_date                   = yield validate_effective_date(effective_date)
          enrollment_eligibility_entity    = yield get_enrollment_eligibility(benefit_sponsorship_id, effective_date)
          benefit_sponsor_catalog_entity   = yield get_benefit_sponsor_catalog_entity(enrollment_eligibility_entity)          

          Success(benefit_sponsor_catalog_entity)
        end

        private

        def validate_effective_date(effective_date)
          Success(effective_date)
        end

        def get_enrollment_eligibility(benefit_sponsorship_id, effective_date)
          result = BenefitSponsors::Operations::BenefitSponsorship::DetermineEnrollmentEligibility.new.call(benefit_sponsorship_id: benefit_sponsorship_id, effective_date: effective_date)

          if result.success?
            result
          else
            Failure("Unable to determine enrollment_eligibility for benefit sponsorship - #{benefit_sponsorship_id}")
          end
        end

        def get_benefit_sponsor_catalog_entity(enrollment_eligibility)
          result = BenefitMarkets::Operations::BenefitMarkets::CreateBenefitSponsorCatalog.new.call({
            enrollment_eligibility: enrollment_eligibility
          })

          if result.success?
            Success(result.value!)
          else
            Failure('Unable to fetch benefit sponsor catalog entity')
          end
        end
      end
    end
  end
end
