# frozen_string_literal: true

module BenefitMarkets
  module Validators
    class ProductContract < Dry::Validation::Contract

      params do
        required(:benefit_market_kind).filled(:symbol)
        required(:application_period).filled(Types::Duration)
        required(:hbx_id).filled(:string)
        required(:title).filled(:string)
        required(:description).filled(:string)
        required(:issuer_profile_id).filled(:string)
        required(:product_package_kinds).array(:symbol)
        required(:kind).filled(:symbol)
        required(:premium_ages).array(Types::Duration)
        required(:provider_directory_url).filled(:string)
        required(:is_reference_plan_eligible).filled(:bool)
        required(:deductible).filled(:string)
        required(:family_deductible).filled(:string)
        required(:issuer_assigned_id).filled(:string)
        required(:service_area_id).filled(:string)
        required(:network_information).filled(:string)
        required(:nationwide).filled(:bool)
        required(:dc_in_network).filled(:bool)

        required(:sbc_document).filled(:hash)
        required(:premium_tables).array(:hash)
      end

      rule(:sbc_document) do
        if key? && value
          result = DocumentContract.call(value)
          key.failure(text: "invalid document", error: result.errors.to_h) if result&.failure?
        end
      end

      rule(:premium_tables).each do
        if key? && value
          result = Products::PremiumTableContract.call(value)
          key.failure(text: "invalid premium table", error: result.errors.to_h) if result&.failure?
        end
      end
    end
  end
end