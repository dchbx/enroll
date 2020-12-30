# frozen_string_literal: true

module BenefitMarkets
  module Entities
    class MemberRelationship < Dry::Struct
      transform_keys(&:to_sym)

      attribute :_id,                       Types::Bson
      attribute :relationship_name,         Types::Strict::Symbol
      attribute :relationship_kinds,        Types::Strict::Array

      attribute :age_threshold,             Types::Integer.optional
      attribute :age_comparison,            Types::Symbol.optional
      attribute :disability_qualifier,      Types::Bool.optional
    end
  end
end