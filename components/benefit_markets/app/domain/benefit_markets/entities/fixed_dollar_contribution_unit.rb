# frozen_string_literal: true

module BenefitMarkets
  module Entities
    class FixedDollarContributionUnit < BenefitMarkets::Entities::ContributionUnit
      transform_keys(&:to_sym)

      attribute :default_contribution_amount,                      Types::Strict::Float

    end
  end
end