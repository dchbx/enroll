# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Validators
      module ContributionModels
        class ContributionModelContract < Dry::Validation::Contract

          params do
            required(:title).filled(:string)
            required(:key).filled(:symbol)
            required(:sponsor_contribution_kind).filled(:string)
            required(:contribution_calculator_kind).filled(:string)
            required(:many_simultaneous_contribution_units).filled(:boolean)
            required(:product_multiplicities).array(:symbol)
            required(:contribution_units).array(:hash)
            required(:member_relationships).array(:hash)
          end

          rule(:conribution_units).each do
            if key? && value
              result = ContributionUnitContract.call(value)
              key.failure(text: "invalid contribution unit for contribution model", error: result.errors.to_h) if result&.failure?
            end
          end

          rule(:member_relationships).each do
            if key? && value
              result = MemberRelationshipContract.call(value)
              key.failure(text: "invalid member relationshp for contribution model", error: result.errors.to_h) if result&.failure?
            end
          end
        end
      end
    end
  end
end