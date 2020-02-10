# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    # include Dry::Monads::Do.for(:call)

    class CreateBenefitSponsorCatalog
      include Dry::Monads[:result, :do]

      # @param [ Date ] effective_date Effective date of the benefit application
      # @param [ Hash ] benefit_market_catalog Benefit Market Catalog for the given Effective Date
      # @param [ Array<BenefitMarkets::Entities::Locations::ServiceArea> ] benefit_market_catalog Benefit Market Catalog for the given Effective Date
      # @param [ Symbol ] market_kind Benefit Marketplace Type
      # @return [ BenefitMarkets::Entities::BenefitSponsorCatalog ] benefit_sponsor_catalog
      def call(params)
        values                = yield validate(params)
        sponsor_catalog_hash  = yield construct_sponsor_catalog(values)
        sponsor_catalog_attrs = yield validate_sponsor_catalog(sponsor_catalog_hash)
        sponsor_catalog       = yield create_sponsor_catalog(sponsor_catalog_attrs.values.data)


        values                = yield validate(params)
        sponsor_catalog_hash  = yield construct_sponsor_catalog(values)
        sponsor_catalog_attrs = yield validate_sponsor_catalog(sponsor_catalog_hash)
        sponsor_catalog       = yield create_sponsor_catalog(sponsor_catalog_attrs.values.data)

        Success(sponsor_catalog)
      end

      private

      def validate(params)
        # effective_date = params[:effective_date]
        # validate effective date
        Success(params)
      end

      def construct_sponsor_catalog(values)
        benefit_market_catalog = values[:benefit_market_catalog]

        enrollment_dates = enrollment_dates_for(values)[:enrollment_dates]

        sponsor_catalog_hash = {
          effective_date: values[:effective_date],
          effective_period: enrollment_dates[:effective_period],
          open_enrollment_period: enrollment_dates[:open_enrollment_period],
          probation_period_kinds: benefit_market_catalog[:probation_period_kinds],
          business_policies: benefit_market_catalog[:business_policies],
          service_areas: values[:service_areas].collect(&:attributes),
          product_packages: build_product_packages(values)
        }

        Success(sponsor_catalog_hash)
      end

      def build_product_packages(values)
        values[:benefit_market_catalog][:product_packages].collect do |product_package|
          BenefitMarkets::Operations::Products::CreateProductPackage.new.call(
            values.merge({product_package: product_package, application_period: @enrollment_dates[:effective_period]})
          ).success
        end
      end

      def validate_sponsor_catalog(catalog_hash)
        contract = BenefitMarkets::Validators::BenefitSponsorCatalogContract.new

        Success(contract.call(catalog_hash))
      end

      def create_sponsor_catalog(attrs)
        catalog_entity = BenefitMarkets::Entities::BenefitSponsorCatalog.new(attrs)

        Success(catalog_entity)
      end

      def enrollment_dates_for(values)
        return @enrollment_dates if defined? @enrollment_dates
        @enrollment_dates = BenefitMarkets::Operations::BenefitMarketCatalog::GetEnrollmentDates.new.call(effective_date: values[:effective_date], market_kind: values[:market_kind]).success
      end
    end
  end
end