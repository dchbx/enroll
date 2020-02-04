# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Validators
      module Products
        class PremiumTableContract < Dry::Validation::Contract

          params do
            required(:effective_period).filled(Types::Duration)
            required(:rating_area).filled(:hash)
            required(:premium_tuples).array(:hash)
          end

          rule(:rating_area) do
            if key? && value
              result = ::RatingAreaContract.call(value)
              key.failure(text: "invalid rating area", error: result.errors.to_h) if result&.failure?
            end
          end

          rule(:premium_tuples).each do
            if key? && value
              result = Products::PremiumTupleContract.call(value)
              key.failure(text: "invalid premium tuple", error: result.errors.to_h) if result&.failure?
            end
          end
        end
      end
    end
  end
end