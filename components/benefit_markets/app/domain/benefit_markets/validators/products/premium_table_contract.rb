# frozen_string_literal: true

module BenefitMarkets
  module Validators
    module Products
      class PremiumTableContract < Dry::Validation::Contract

        params do
          required(:_id).filled(Types::Bson)
          required(:effective_period).filled(type?: Range)
          required(:rating_area_id).filled(Types::Bson)
          optional(:premium_tuples).array(:hash)

          before(:value_coercer) do |result|
            result_hash = result.to_h
            if result_hash[:effective_period].is_a?(Hash)
              result_hash[:effective_period].deep_symbolize_keys
              result_hash.merge({effective_period: (result_hash[:effective_period][:min]..result_hash[:effective_period][:max])})
            end
          end
        end

        rule(:premium_tuples).each do
          if key? && value
            result = PremiumTupleContract.new.call(value)
            key.failure(text: "invalid premium tuple", error: result.errors.to_h) if result&.failure?
          end
        end
      end
    end
  end
end
