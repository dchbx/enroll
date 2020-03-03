# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module BenefitSponsorCatalog
      # Creates BenefitSponsorCatalog object
      class Create
        send(:include, Dry::Monads[:result, :do])

        # @param [ Date ] effective_date Effective date of the benefit application
        # @param [ String ] sponsorship_id Benefit Sponsorship Id
        # @return [ BenefitSponsors::Entities::EnrollmentEligibility ] enrollment_eligibility
        def call(effective_date:, benefit_sponsorship_id:)
          effective_date                              = yield validate_effective_date(effective_date)
          enrollment_eligibility_entity               = yield get_enrollment_eligibility(benefit_sponsorship_id, effective_date)
          benefit_sponsorship                         = yield find_benefit_sponsorship(benefit_sponsorship_id)
          service_areas_entities                      = yield get_service_areas_entities(benefit_sponsorship, effective_date)
          market_kind                                 = yield get_market_kind(benefit_sponsorship)
          benefit_sponsor_catalog_entity              = yield get_benefit_sponsor_catalog_entity(effective_date, service_areas_entities, market_kind)

          build_benefit_sponsor_catalog               = yield build_benefit_sponsor_catalog(benefit_sponsor_catalog_entity)
          contribution_model_title                    = yield fetch_contribution_model_title(enrollment_eligibility_entity)
          catalog_with_assigned_contribution_model    = yield assign_contribution_model(build_benefit_sponsor_catalog, contribution_model_title)
          persisted_catalog                           = yield persist_catalog(catalog_with_assigned_contribution_model)

          Success(persisted_catalog)
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

        def get_market_kind(benefit_sponsorship)
          market_kind = benefit_sponsorship.market_kind

          Success(market_kind)
        end

        def get_service_areas_entities(benefit_sponsorship, effective_date)
          benefit_sponsorship.service_areas_on(effective_date).collect do |service_area|
            BenefitMarkets::Operations::ServiceAreas::Create.new.call(service_area_params: service_area.as_json)
          end
        end

        def find_benefit_sponsorship(benefit_sponsorship_id)
          result = BenefitSponsors::Operations::BenefitSponsorship::FindModel.new.call(benefit_sponsorship_id: benefit_sponsorship_id)

          if result.success?
            result
          else
            result.failure
          end
        end

        def get_benefit_sponsor_catalog_entity(effective_date, service_areas_entities, market_kind)
          result = BenefitMarkets::Operations::BenefitMarkets::CreateBenefitSponsorCatalog.new.call(effective_date: effective_date, service_areas: service_areas_entities.to_a, market_kind: market_kind)

          if result.success?
            Success(result.success)
          else
            Failure('Unable to fetch benefit sponsor catalog entity')
          end
        end

        def build_benefit_sponsor_catalog(entity)
          params = entity.to_h
          catalog = BenefitMarkets::BenefitSponsorCatalog.new(params)

          Success(catalog)
        end

        def fetch_contribution_model_title(enrollment_eligibility_entity)
          title =
            case enrollment_eligibility_entity.success.application_type
            when 'initial'
              'Zero Percent Sponsor Fixed Percent Contribution Model'
            when 'renewing'
              'Fifty Percent Sponsor Fixed Percent Contribution Model'
            end

          Success(title)
        end

        def assign_contribution_model(benefit_sponsor_catalog, contribution_model_title)
          benefit_sponsor_catalog.product_packages.each do |product_package|
            assigned_contribution_model = product_package.contribution_models.where(title: contribution_model_title).first
            product_package.assigned_contribution_model = assigned_contribution_model
          end

          Success(benefit_sponsor_catalog)
        end

        def persist_catalog(benefit_sponsor_catalog)
          if benefit_sponsor_catalog.save
            Success(benefit_sponsor_catalog)
          else
            Failure(:benefit_sponsor_catalog_not_created)
          end
        end
      end
    end
  end
end