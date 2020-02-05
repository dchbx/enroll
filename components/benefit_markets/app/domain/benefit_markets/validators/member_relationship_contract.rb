# frozen_string_literal: true

module BenefitMarkets
  module Validators
    class MemberRelationshipContract < Dry::Validation::Contract

      params do
        required(:relationship_name).filled(:symbol)
        required(:relationship_kinds).array(:hash)
        optional(:age_threshold).value(:integer)
        optional(:age_comparison).value(:symbol)
        optional(:disability_qualifier).value(:bool)
      end
    end
  end
end