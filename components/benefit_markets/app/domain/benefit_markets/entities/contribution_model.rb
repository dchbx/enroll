# frozen_string_literal: true

module BenefitMarkets
  module Entities
    class ContributionModel < Dry::Struct
      transform_keys(&:to_sym)

      attribute :_id,                                   Types::Bson
      attribute :title,                                 Types::Strict::String
      attribute :key,                                   Types::Symbol.optional
      attribute :sponsor_contribution_kind,             Types::Strict::String
      attribute :contribution_calculator_kind,          Types::Strict::String
      attribute :many_simultaneous_contribution_units,  Types::Strict::Bool
      attribute :product_multiplicities,                Types::Strict::Array
      attribute :contribution_units,                    Types::Array.of(BenefitMarkets::Entities::ContributionUnit)
      attribute :member_relationships,                  Types::Array.of(BenefitMarkets::Entities::MemberRelationship)

    end
  end
end