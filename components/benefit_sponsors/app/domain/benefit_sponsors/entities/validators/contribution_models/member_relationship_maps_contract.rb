# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Validators
      module ContributionModels
        class MemberRelationshipMapsContract < Dry::Validation::Contract

          params do
            required(:relationship_name).filled(:symbol)
            required(:operator).filled(:symbol)
            required(:count).filled(:integer)
          end

          rule(:operator) do
            key.failure('unsupported operator for member relationship map') unless [:>=, :<=, :==, :<, :>].include? value
          end
        end
      end
    end
  end
end