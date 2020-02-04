# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Validators
      module PricingModels
        class PricingUnitContract < ApplicationContract

          params do
            required(:name).filled(:string)
            required(:display_name).filled(:string)
            required(:order).filled(:integer)
          end
        end
      end
    end
  end
end