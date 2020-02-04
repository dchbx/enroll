# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Validators
      class BenefitSponsorCatalogContract < Dry::Validation::Contract

        params do
          required(:effective_date).filled(:date)
          required(:effective_period).value(Types::Duration)
          required(:open_enrollment_period).value(Types::Duration)
          required(:probation_period_kinds).array(:symbol)
          optional(:benefit_application).maybe(:hash)
          required(:product_packages).array(:hash)
          required(:service_areas).array(:hash)
        end

        rule(:benefit_application) do
          if key? && value
            result = BenefitApplicationContract.call(value)
            key.failure(text: "invalid benefit application", error: result.errors.to_h) if result&.failure?
          end
        end

        rule(:product_packages).each do
          if key? && value 
            result = ProductPackageContract.call(value)
            key.failure(text: "invalid product package", error: result.errors.to_h) if result&.failure?
          end
        end

        rule(:service_areas).each do
          if key? && value
            result = ServiceAreaContract.call(value)
            key.failure(text: "invalid service area", error: result.errors.to_h) if result&.failure?
          end
        end
      end
    end
  end
end