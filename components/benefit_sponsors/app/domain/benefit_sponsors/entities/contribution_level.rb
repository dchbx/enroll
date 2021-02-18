# frozen_string_literal: true

module BenefitSponsors
  module Entities
    class ContributionLevel < Dry::Struct
      transform_keys(&:to_sym)

      attribute :display_name,                      Types::Strict::String
      attribute :contribution_unit_id,              Types::Bson
      attribute :is_offered,                        Types::Strict::Bool
      attribute :order,                             Types::Strict::Integer
      attribute :contribution_factor,               Types::Strict::Float
      attribute :min_contribution_factor,           Types::Strict::Float
      attribute :contribution_cap,                  Types::Float.optional  # TODO: Revisit Fix for fehb market
      attribute :flat_contribution_amount,          Types::Float.optional

    end
  end
end
