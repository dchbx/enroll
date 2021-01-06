# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module Organizations
      # General Organization Contract is to validate submitted params while persisting General Organization
      class GeneralOrganizationContract < OrganizationContract

        params do
          required(:fein).filled(:string)
        end
      end
    end
  end
end
