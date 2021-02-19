# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module Organizations
      # Exempt Organization Contract is to validate submitted params while persisting Exempt Organization
      class ExemptOrganizationContract < OrganizationContract

        params do
          optional(:fein).maybe(:string)
        end
      end
    end
  end
end
