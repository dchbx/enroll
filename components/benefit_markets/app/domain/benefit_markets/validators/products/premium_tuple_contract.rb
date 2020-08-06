# frozen_string_literal: true

module BenefitMarkets
  module Validators
    module Products
      class PremiumTupleContract < Dry::Validation::Contract

        params do
          required(:_id).filled(Types::Bson)
          required(:age).filled(:integer)
          required(:cost).filled(:float)
        end
      end
    end
  end
end