# frozen_string_literal: true

module BenefitMarkets
  module Entities
    module SponsoredBenefits
      class ContributionLevel < Dry::Struct
        transform_keys(&:to_sym)

        attribute :display_name, Types::Strict::String
        attribute :contribution_unit_id, Types::Strict::String
        attribute :is_offered, Types::Strict::Bool
        attribute :order, Types::Strict::Integer
        attribute :contribution_factor, Types::Strict::Float
        attribute :min_contribution_factor, Types::Strict::Float
        attribute :contribution_cap, Types::Strict::Float
        attribute :flat_contribution_amount, Types::Strict::Float

      end
    end
  end
end