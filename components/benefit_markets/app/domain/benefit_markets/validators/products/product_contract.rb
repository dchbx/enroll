# frozen_string_literal: true

module BenefitMarkets
  module Validators
    module Products
      class ProductContract < Dry::Validation::Contract

        params do
          required(:_id).filled(Types::Bson)
          required(:benefit_market_kind).filled(:symbol)
          required(:application_period).filled(type?: Range)
          optional(:hbx_id).maybe(:string)
          required(:title).filled(:string)
          optional(:description).maybe(:string)
          required(:issuer_profile_id).filled(Types::Bson)
          required(:product_package_kinds).array(:symbol)
          required(:kind).filled(:symbol)
          required(:premium_ages).filled(type?: Range)
          optional(:provider_directory_url).maybe(:string)
          required(:is_reference_plan_eligible).filled(:bool)
          optional(:deductible).maybe(:string)
          optional(:family_deductible).maybe(:string)
          optional(:issuer_assigned_id).maybe(:string)
          required(:service_area_id).filled(Types::Bson)
          optional(:network_information).maybe(:string)
          optional(:nationwide).maybe(:bool)
          optional(:dc_in_network).maybe(:bool)
          optional(:renewal_product_id).maybe(Types::Bson)
          optional(:sbc_document).maybe(:hash)
          required(:premium_tables).array(:hash)

          before(:value_coercer) do |result|
            result_hash = result.to_h

            if result_hash[:application_period].is_a?(Hash)
              result_hash[:application_period].deep_symbolize_keys
              result_hash.merge!({application_period: (result_hash[:application_period][:min]..result_hash[:application_period][:max])})
            end

            if result_hash[:premium_ages].is_a?(Hash)
              result_hash[:premium_ages].deep_symbolize_keys
              result_hash.merge!({premium_ages: (result_hash[:premium_ages][:min]..result_hash[:premium_ages][:max])})
            end
            result_hash
          end
        end

        rule(:sbc_document) do
          if key? && value
            result = DocumentContract.new.call(value)
            key.failure(text: "invalid document", error: result.errors.to_h) if result&.failure?
          end
        end

        rule(:premium_tables).each do
          if key? && value
            result = PremiumTableContract.new.call(value)
            key.failure(text: "invalid premium table", error: result.errors.to_h) if result&.failure?
          end
        end
      end
    end
  end
end
