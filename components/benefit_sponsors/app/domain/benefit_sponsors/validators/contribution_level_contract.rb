# frozen_string_literal: true

module BenefitSponsors
  module Validators
    class ContributionLevelContract < Dry::Validation::Contract

      params do
        required(:display_name).filled(:string)
        required(:contribution_unit_id).filled(:string)
        required(:is_offered).filled(:bool)
        required(:order).filled(:integer)
        required(:contribution_factor).filled(:float)
        required(:min_contribution_factor).filled(:float)
        required(:contribution_cap).filled(:float)
        required(:flat_contribution_amount).filled(:float)
      end
    end
  end
end