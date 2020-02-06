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


        Success(sponsor_catalog)
      end

      private

      def validate(params)
        # effective_date = params[:effective_date]
        # validate effective date
        Success(params)
      end

      def create_sponsor_catalog(values)
        benefit_market_catalog = values[:benefit_sponsor_catalog]

        enrollment_dates = BenefitMarkets::Operations::BenefitMarketCatalog::GetEnrollmentDates.new.call(effective_date: values[:effective_date], market_kind: values[:market_kind])

        sponsor_catalog_hash = {
          effective_date: values[:effective_date],
          effective_period: enrollment_dates[:effective_period],
          open_enrollment_period: enrollment_dates[:open_enrollment_period],
          probation_period_kinds: benefit_market_catalog[:probation_period_kinds],
          business_policies: benefit_market_catalog[:business_policies],
          service_areas: values[:service_areas].collect(&:to_h),
          product_packages: build_product_packages(benefit_market_catalog, values)
        }
      end

      def build_product_packages(benefit_market_catalog, values)
        benefit_market_catalog[:product_packages].collect do |product_package|
          filter_product_package_for(values[:service_areas], product_package)
        end
      end

      def filter_product_packages(service_areas, product_package)
        product_package_hash = product_package.except(:products)
        product_package_hash[:products] = BenefitMarkets::Operations::BenefitMarketCatalog::ScopeProductsByServiceArea.new.call({
          effective_date: values[:effective_date], 
          market_kind: values[:market_kind], 
          package_kind: product_package[:package_kind]
        })

      #   {
      #   title: market_product_package.title,
      #   description: market_product_package.description,
      #   product_kind: market_product_package.product_kind,
      #   benefit_kind: market_product_package.benefit_kind, 
      #   package_kind: market_product_package.package_kind
      # )

      # product_package.application_period = benefit_sponsor_catalog.effective_period
      # product_package.contribution_model = market_product_package.contribution_model.create_copy_for_embedding
      # product_package.pricing_model = market_product_package.pricing_model.create_copy_for_embedding
      # product_package.products = market_product_package.load_embedded_products(benefit_sponsor_catalog.service_areas, @effective_date)
      # product_package

        }
        benefit_market_catalog[:product_packages].collect{}
      end

      # def extract_attributes(sponosor_eligibility, contribution_model)
      #   attrs = {
      #     effective_date: sponsor_eligibility[:effective_date],
      #     benefit_type: sponsor_eligibility[:benefit_type],
      #     exception_granted: sponsor_eligibility[:flexibile_contribution_model_enabled],
      #     contribution_model: contribution_model.attributes.slice(:_id, :contribution_type, :effective_period, :eligibility_policies)
      #   }
      #   Success(attrs)
      # end

      def assign_default_contribution_model(benefit_sponsor_catalog)
        enrollment_eligibility = benefit_sponsorship.enrollment_eligibility_for(effective_date)
        business_policy = business_policy_for(benefit_sponsor_catalog, enrollment_eligibility)
        contribution_model_title = business_policy.policy_result.to_s.humanize.titleize

        benefit_sponsor_catalog.product_packages.each do |product_package|
          product_package.assigned_contribution_model = product_package.contribution_models.detect do |cm|
            cm.title == contribution_model_title
          end
        end

        Success(contribution_model_criteria)
      end

      def validate(params)
        contract = BenefitMarkets::Entities::Validators::BenefitSponsorshipContract.new

        Success(contract.call(params))
      end
      # benefit_sponsorship
      # effective_date
      # benefit_market

      def get_benefit_market_catalog(values)
        benefit_market.benefit_market_catalog_for(values)
      end

      def build(_values)
        benefit_market = benefit_sponsorship.benefit_market
        benefit_market.benefit_market_catalog_for(effective_date)

        benefit_sponsor_catalog = benefit_market.benefit_sponsor_catalog_for(benefit_sponsorship.recorded_service_areas, effective_date)

        Success(benefit_sponsor_catalog)
      end

      def business_policy_for(benefit_sponsor_catalog, _enrollment_eligibility)
        eligibility_policy = benefit_sponsor_catalog.enrollment_eligibility_policy
        policies = eligibility_policy.business_policies_for(:create_application)
        policies.detect{|business_policy| business_policy.is_satisfied?(enrollment.eligibility)}
      end
    end
  end
end