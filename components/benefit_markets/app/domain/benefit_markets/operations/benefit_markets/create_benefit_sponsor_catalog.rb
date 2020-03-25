# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module BenefitMarkets
      # Creates benefit sponsor catalog entity
      class CreateBenefitSponsorCatalog
        # send(:include, Dry::Monads::Do.for(:call))
        send(:include, Dry::Monads[:result, :do])

        # @param [ Date ] effective_date Effective date of the benefit application
        # @param [ Array<BenefitMarkets::Entities::ServiceArea> ] service_areas Service Areas based on Benefit Sponsor primary office location
        # @param [ Symbol ] market_kind Benefit Marketplace Type
        # @return [ BenefitMarkets::Entities::BenefitSponsorCatalog ] benefit_sponsor_catalog
        def call(service_areas:, enrollment_eligibility:)
          benefit_market_catalog = yield find_benefit_market_catalog(enrollment_eligibility)
          sponsor_catalog_params = yield get_enrollment_policies(benefit_market_catalog, enrollment_eligibility, service_areas)
          product_packages       = yield build_product_packages(benefit_market_catalog, service_areas, sponsor_catalog_params[:effective_period], enrollment_eligibility)
          sponsor_catalog        = yield create(sponsor_catalog_params, product_packages)

          Success(sponsor_catalog)
        end

        private

        def get_enrollment_policies(benefit_market_catalog, enrollment_eligibility, service_areas)
          benefit_market_catalog = benefit_market_catalog.value!
          effective_date = enrollment_eligibility.effective_date
          policies = {
            effective_date: effective_date,
            effective_period: benefit_market_catalog.effective_period_on(effective_date),
            open_enrollment_period: benefit_market_catalog.open_enrollment_period_on(effective_date),
            probation_period_kinds: benefit_market_catalog.probation_period_kinds,
            service_area_ids: service_areas.pluck(:_id)
          }

          Success(policies)
        end

        def build_product_packages(benefit_market_catalog, service_areas, application_period, enrollment_eligibility)
          benefit_market_catalog = benefit_market_catalog.value!

          product_packages = benefit_market_catalog.product_packages.collect do |product_package|
            product_package_entity_for(product_package, service_areas, application_period, enrollment_eligibility)
          end

          if product_packages.none?(&:failure?)
            Success(product_packages.map(&:value!))
          else
            Failure(product_packages.reduce([]){|list, package| list << package.failure if package.failure? })
          end
        end

        def product_package_entity_for(product_package, service_areas, application_period, enrollment_eligibility)
          product_package_params     = product_package.as_json.deep_symbolize_keys.except(:products)
          contribution_models_params = product_package_params.delete(:contribution_models)
          product_package_params[:application_period]  = application_period
          product_package_params[:products]            = filter_products_by_service_areas(product_package, enrollment_eligibility.effective_date, service_areas).value!
          product_package_params[:contribution_models] = contribution_models_for(contribution_models_params)

          ::BenefitMarkets::Operations::ProductPackages::Create.new.call(product_package_params: product_package_params, enrollment_eligibility: enrollment_eligibility)
        end

        def create(sponsor_catalog_params, product_packages)
          benefit_sponsor_catalog = ::BenefitMarkets::Operations::BenefitSponsorCatalogs::Create.new.call(sponsor_catalog_params: sponsor_catalog_params.merge(product_packages: product_packages))

          if benefit_sponsor_catalog.success?
            Success(benefit_sponsor_catalog.value!)
          else
            Failure(benefit_sponsor_catalog.failure)
          end
        end

        def find_benefit_market_catalog(enrollment_eligibility)
          market_catalog = ::BenefitMarkets::Operations::BenefitMarketCatalogs::FindModel.new.call(effective_date: enrollment_eligibility.effective_date, market_kind: enrollment_eligibility.market_kind)

          Success(market_catalog)
        end

        def filter_products_by_service_areas(product_package, effective_date, service_areas)
          ::BenefitMarkets::Operations::Products::Find.new.call(effective_date: effective_date, service_areas: service_areas, product_package: product_package)
        end

        def contribution_models_for(contribution_models_params)
          contribution_models_params.collect do |contribution_params|
            ::BenefitMarkets::Operations::ContributionModels::Create.new.call(contribution_params: contribution_params).value!
          end
        end
      end
    end
  end
end
