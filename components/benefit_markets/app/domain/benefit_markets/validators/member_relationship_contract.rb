# frozen_string_literal: true

module BenefitMarkets
  module Validators
    class MemberRelationshipContract < Dry::Validation::Contract

      params do
        required(:relationship_name).filled(:symbol)
        required(:relationship_kinds).array(:hash)
        optional(:age_threshold).maybe(:integer)
        optional(:age_comparison).maybe(:symbol)
        optional(:disability_qualifier).maybe(:bool)
      end
    end
  end
end