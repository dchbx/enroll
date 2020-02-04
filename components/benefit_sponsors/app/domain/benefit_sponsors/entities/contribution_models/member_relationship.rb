# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module ContributionModels
      class MemberRelationship < Dry::Struct
        transform_keys(&:to_sym)

        attribute :relationship_name,         Types::Strict::Symbol
        attribute :relationship_kinds,        Types::Strict::Array
        attribute :age_threshold,             Types::Maybe::Integer
        attribute :age_comparison,            Types::Maybe::Symbol
        attribute :disability_qualifier,      Types::Maybe::Bool

      end
    end
  end
end