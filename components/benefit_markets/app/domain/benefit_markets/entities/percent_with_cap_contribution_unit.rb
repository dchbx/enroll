# frozen_string_literal: true

module BenefitMarkets
  module Entities
    class PercentWithCapContributionUnit < BenefitMarkets::Entities::ContributionUnit
      transform_keys(&:to_sym)

      attribute :default_contribution_factor,                      Types::Strict::Float
      attribute :default_contribution_cap,                         Types::Strict::Float
      attribute :minimum_contribution_factor,                      Types::Strict::Float

    end
  end
end