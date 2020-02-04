# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Validators
      module Products
        class PremiumTupleContract < Dry::Validation::Contract

          params do
            required(:age).filled(:integer)
            required(:cost).filled(:float)
          end
        end
      end
    end
  end
end