# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module Organizations
      class OrganizationContract < Dry::Validation::Contract

        params do
          optional(:home_page).maybe(:string)
          required(:legal_name).filled(:string)
          optional(:dba).maybe(:string)
          required(:entity_kind).filled(:symbol)
          required(:site_id).filled(Types::Bson)
          required(:profiles).array(:hash)
        end

        rule(:profile).each do
          if key? && value
            result = BenefitSponsors::Validators::Profiles::AgencyProfileContract.new.call(value)
            key.failure(text: "invalid profile", error: result.errors.to_h) if result&.failure?
          end
        end
      end
    end
  end
end