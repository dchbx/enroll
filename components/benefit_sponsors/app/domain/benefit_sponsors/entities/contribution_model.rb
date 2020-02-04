# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class ContributionModel < Dry::Struct
      transform_keys(&:to_sym)

      attribute :title,                         Types::Strict::String
      attribute :key,                           Types::Strict::String
      attribute :sponsor_contribution_kind,     Types::Strict::String
      attribute :contribution_calculator_kind,  Types::Strict::String
      attribute :many_simultaneous_contribution_units,  Types::Strict::Bool
      attribute :product_multiplicities, Types::Strict::Array
      attribute :contribution_units, Types::Array.of(ContributionUnit)
      attribute :member_relationships, Types::Array.of(MemberRealtionship)

    end
  end
end