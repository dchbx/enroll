# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module Organizations
      # General Organization Contract is to validate submitted params while persisting General Organization
      class GeneralOrganizationContract < Dry::Validation::Contract

        params do
          required(:entity_kind).filled(:string)
          required(:legal_name).filled(:string)
          optional(:dba).maybe(:string)
          required(:fein).filled(:string)
          required(:profile).filled(:hash)
        end

        rule(:profile) do
          if key? && value
            result = BenefitSponsors::Validators::Profiles::AgencyProfileContract.new.call(value)
            key.failure(text: "invalid profile", error: result.errors.to_h) if result&.failure?
          end
        end
      end
    end
  end
end
