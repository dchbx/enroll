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