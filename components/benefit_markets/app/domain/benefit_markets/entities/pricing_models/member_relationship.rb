# frozen_string_literal: true

module BenefitMarkets
  module Entities
    module PricingModels
      class MemberRelationship < Dry::Struct
        transform_keys(&:to_sym)

        attribute :relationship_name,         Types::Strict::Symbol
        attribute :relationship_kinds,        Types::Strict::Array

        attribute :age_threshold,             Types::Integer.optional.meta(omittable: true)
        attribute :age_comparison,            Types::Symbol.optional.meta(omittable: true)
        attribute :disability_qualifier,      Types::Bool.optional.meta(omittable: true)
      end
    end
  end
end