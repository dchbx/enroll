# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    module ProductPackages
      class Create
        # include Dry::Monads::Do.for(:call)
        include Dry::Monads[:result, :do]

        # @param [ Hash ] params Product Package attributes
        # @param [ Array<BenefitMarkets::Entities::Product> ] products Product
        # @return [ BenefitMarkets::Entities::ProductPackage ] product_package Product Package
        def call(product_package_params:, enrollment_eligibility:)
          product_package_attrs       = yield set_assigned_contribution_model(product_package_params, enrollment_eligibility)
          product_package_values      = yield validate(product_package_attrs, enrollment_eligibility)
          product_package             = yield create(product_package_values)

          Success(product_package)
        end

        private

        def validate(product_package_params, enrollment_eligibility)
          result =
            if enrollment_eligibility.market_kind == :fehb || product_package_params[:product_kind] != :health
              ::BenefitMarkets::Validators::Products::LegacyProductPackageContract.new.call(product_package_params)
            else
              ::BenefitMarkets::Validators::Products::ProductPackageContract.new.call(product_package_params)
            end

          if result.success?
            Success(result.to_h)
          else
            Failure(result.errors.to_h)
          end
        end

        def set_assigned_contribution_model(product_package_values, enrollment_eligibility)
          key = "assign_contribution_model_#{enrollment_eligibility.market_kind}".to_sym
          result =
            if ::EnrollRegistry.feature_enabled?(key) && product_package_values[:product_kind] == :health
              contribution_model = ::EnrollRegistry[key] do
                {
                  product_package_values: product_package_values,
                  enrollment_eligibility: enrollment_eligibility
                }
              end.value!
              contribution_model[:product_package_values]
            else
              product_package_values[:assigned_contribution_model] = nil
              product_package_values[:contribution_models] = []
              product_package_values
            end

          Success(result)
        end

        def create(product_package_values)
          product_package = ::BenefitMarkets::Entities::ProductPackage.new(product_package_values)

          Success(product_package)
        end
      end
    end
  end
end
