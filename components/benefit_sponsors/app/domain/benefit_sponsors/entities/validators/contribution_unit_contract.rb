# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Validators
      class ContributionUnitContract < ApplicationContract

        params do
          required(:name).filled(:string)
          required(:display_name).filled(:string)
          required(:order).filled(:integer)
        end
      end
    end
  end
end