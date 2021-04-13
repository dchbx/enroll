# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module BenefitMarketCatalogs
      # include Dry::Monads[:result]
      # include Dry::Monads::Do.for(:call)

      class Renew
        include Dry::Monads[:result, :do]

        # @param [ Date ] effective_date Effective Date of the Current Benefit Market Catalog
        # @param [ Symbol ] market_kind BenefitMarket market kind
        def call(params)
          # paramss[:options][:overwrite] ||= false
          existing_catalog = yield find_benefit_market_catalog(params)
          new_catalog_params = yield construct_attributes(existing_catalog)
          product_package_params = yield renew_product_packages(existing_catalog, new_catalog_params[:application_period])
          benefit_market_catalog = yield renew(new_catalog_params, product_package_params)

          Success(benefit_market_catalog)
        end

        private

        def construct_attributes(existing_catalog)
          renewal_start_date = existing_catalog.application_period.max + 1.day

          attributes = {
            title: existing_catalog.title,
            description: existing_catalog.description,
            application_interval_kind: existing_catalog.application_interval_kind,
            application_period: renewal_start_date..renewal_start_date.next_year.prev_day,
            probation_period_kinds: ::BenefitMarkets::PROBATION_PERIOD_KINDS
          }

          Success(attributes)
        end

        def renew_product_packages(existing_catalog, application_period)
          renewed_packages = existing_catalog.product_packages.collect do |existing_product_package|
            product_package_attributes = existing_product_package.as_json.deep_symbolize_keys
            product_package_attributes.merge!(application_period: application_period)

            result = ::BenefitMarkets::Operations::ProductPackages::Renew.new.call(product_package_attributes)
            raise StandardError, result.errors.to_h if result.failure?
            result.success
          end

          Success(renewed_packages)
        rescue StandardError => e
          Failure(e)
        end

        def renew(new_catalog_params, product_package_params)
          ::BenefitMarkets::Operations::BenefitMarketCatalogs::Create.new.call(new_catalog_params.merge(product_packages: product_package_params))
        end

        def find_benefit_market_catalog(params)
          ::BenefitMarkets::Operations::BenefitMarketCatalogs::FindModel.new.call(params)
        end
      end
    end
  end
end
