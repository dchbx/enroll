# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module BenefitMarket
      # Creates benefit sponsor catalog entity
      class CreateBenefitSponsorCatalog
        # send(:include, Dry::Monads::Do.for(:call))
        send(:include, Dry::Monads[:result, :do])

        # @param [ Date ] effective_date Effective date of the benefit application
        # @param [ Array<BenefitMarkets::Entities::ServiceArea> ] service_areas Service Areas based on Benefit Sponsor primary office location
        # @param [ Symbol ] market_kind Benefit Marketplace Type
        # @return [ BenefitMarkets::Entities::BenefitSponsorCatalog ] benefit_sponsor_catalog
        def call(effective_date:, service_areas:, market_kind:)
          effective_date         = yield validate_effective_date(effective_date)
          market_kind            = yield validate_market_kind(market_kind)
          benefit_market_catalog = yield find_benefit_market_catalog(effective_date, market_kind)
          sponsor_catalog_params = yield get_enrollment_policies(benefit_market_catalog.value!, effective_date, service_areas)
          product_packages       = yield build_product_packages(benefit_market_catalog.value!, effective_date, service_areas, sponsor_catalog_params[:effective_period])
          sponsor_catalog        = yield create(sponsor_catalog_params, product_packages)

          Success(sponsor_catalog)
        end

        private

        def validate_effective_date(effective_date)

          Success(effective_date)
        end

        def validate_market_kind(market_kind)

          Success(market_kind)
        end

        def get_enrollment_policies(benefit_market_catalog, effective_date, service_areas)
          policies = {
            effective_date: effective_date,
            effective_period: benefit_market_catalog.effective_period_on(effective_date),
            open_enrollment_period: benefit_market_catalog.open_enrollment_period_on(effective_date),
            probation_period_kinds: benefit_market_catalog.probation_period_kinds,
            # business_policies: benefit_market_catalog.business_policies.collect(&:to_h),
            service_areas: service_areas
          }
          
          Success(policies)
        end

        def build_product_packages(benefit_market_catalog, effective_date, service_areas, application_period)
          product_packages = benefit_market_catalog.product_packages.collect do |product_package|
            product_package_params = product_package.attributes.except(:products)
            product_package_params.merge!(application_period: application_period)
            filtered_products = filter_products_by_service_areas(product_package, effective_date, service_areas).value!
            BenefitMarkets::Operations::ProductPackage::Create.new.call(product_package_params, filtered_products).value!
          end

          Success(product_packages)
        end

        def filter_products_by_service_areas(product_package, effective_date, service_areas)
          BenefitMarkets::Operations::Products::FindBenefitMarketProducts.new.call(effective_date: effective_date, service_areas: service_areas, product_package: product_package)
        end

        def create(sponsor_catalog_params, product_packages)
          benefit_sponsor_catalog = BenefitMarkets::Operations::BenefitSponsorCatalog::Create.new.call(sponsor_catalog_params, product_packages)
        
          Success(benefit_sponsor_catalog)
        end

        def find_benefit_market_catalog(effective_date, market_kind)
          market_catalog = BenefitMarkets::Operations::BenefitMarketCatalog::FindModel.new.call({effective_date: effective_date, market_kind: market_kind})

          Success(market_catalog)
        end
      end
    end
  end
end