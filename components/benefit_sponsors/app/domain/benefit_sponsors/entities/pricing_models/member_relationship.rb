# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module PricingModels
      class MemberRelationship < Dry::Struct
        transform_keys(&:to_sym)

        attribute :relationship_name, Types::Strict::Symbol
        attribute :relationship_kinds, Types::Strict::Array
        attribute :age_threshold, Types::Maybe::Strict::Integer
        attribute :age_comparison, Types::Maybe::Strict::Symbol
        attribute :disability_qualifier, Types::Strict::Bool

      end
    end
  end
end