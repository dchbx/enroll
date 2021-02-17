# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module SponsoredBenefits
      class ContributionLevelContract < Dry::Validation::Contract

        params do
          required(:display_name).filled(:string)
          required(:contribution_unit_id).filled(Types::Bson)
          required(:is_offered).filled(:bool)
          required(:order).filled(:integer)
          required(:contribution_factor).filled(:float)
          required(:min_contribution_factor).filled(:float)
          required(:contribution_cap).maybe(:string)  # TODO: Revisit Fix for fehb market
          required(:flat_contribution_amount).maybe(:string)
        end
      end
    end
  end
end
