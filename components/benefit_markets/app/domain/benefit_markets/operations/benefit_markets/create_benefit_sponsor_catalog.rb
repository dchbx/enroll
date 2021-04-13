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
        def call(enrollment_eligibility:)
          benefit_market_catalog = yield find_benefit_market_catalog(enrollment_eligibility)
          sponsor_catalog_params = yield get_enrollment_policies(benefit_market_catalog, enrollment_eligibility)
          product_packages       = yield build_product_packages(benefit_market_catalog, sponsor_catalog_params[:effective_period], enrollment_eligibility)
          sponsor_catalog        = yield create(sponsor_catalog_params, product_packages)

          Success(sponsor_catalog)
        end

        private

        def get_enrollment_policies(benefit_market_catalog, enrollment_eligibility)
          benefit_market_catalog = benefit_market_catalog.value!
          effective_date = enrollment_eligibility.effective_date
          policies = {
            effective_date: effective_date,
            effective_period: benefit_market_catalog.effective_period_on(effective_date),
            open_enrollment_period: benefit_market_catalog.open_enrollment_period_on(effective_date),
            probation_period_kinds: benefit_market_catalog.probation_period_kinds,
            service_area_ids: enrollment_eligibility.service_areas.pluck(:_id)
          }

          Success(policies)
        end

        def build_product_packages(benefit_market_catalog, application_period, enrollment_eligibility)
          benefit_market_catalog = benefit_market_catalog.value!

          product_packages = benefit_market_catalog.product_packages.collect do |product_package|
            product_package_entity_for(product_package, application_period, enrollment_eligibility)
          end

          if product_packages.none?(&:failure?)
            Success(product_packages.map(&:value!))
          else
            Failure(product_packages.reduce([]){|list, package| list << package.failure if package.failure? })
          end
        end

        def product_package_entity_for(product_package, application_period, enrollment_eligibility)
          package_kind               = product_package[:package_kind]
          product_package_params     = product_package.as_json.deep_symbolize_keys.except(:products)
          contribution_models_params = product_package_params.delete(:contribution_models) || []
          contribution_model_params  = product_package_params.delete(:contribution_model)
          pricing_units_params       = product_package_params[:pricing_model].delete(:pricing_units)
          product_package_params[:application_period]            = application_period
          product_package_params[:products]                      = filter_products_by_service_areas(product_package, enrollment_eligibility).value!
          # Skipping because we are not creating contribution models for dental as they don't have relaxed rules.
          product_package_params[:contribution_models]           = contribution_models_for(contribution_models_params) if product_package[:product_kind] == :health
          product_package_params[:contribution_model]            = build_contribution_model_entity(contribution_model_params)
          product_package_params[:pricing_model][:pricing_units] = build_pricing_units_entities(pricing_units_params, package_kind)

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

        def filter_products_by_service_areas(product_package, enrollment_eligibility)
          ::BenefitMarkets::Operations::Products::Find.new.call(effective_date: enrollment_eligibility.effective_date, service_areas: enrollment_eligibility.service_areas, product_package: product_package)
        end

        def build_pricing_units_entities(pricing_units_params, package_kind)
          pricing_units_params.collect do |pricing_unit_params|
            ::BenefitMarkets::Operations::PricingUnits::Create.new.call(pricing_unit_params: pricing_unit_params, package_kind: package_kind).value!
          end
        end

        def build_contribution_model_entity(params)
          contribution_model_entity = ::BenefitMarkets::Operations::ContributionModels::Create.new.call(contribution_params: params).value!
        end

        def contribution_models_for(contribution_models_params)
          contribution_models_params.collect do |contribution_model_params|
            build_contribution_model_entity(contribution_model_params)
          end
        end
      end
    end
  end
end