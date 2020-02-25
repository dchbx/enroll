# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module Organizations
      class OrganizationContract < Dry::Validation::Contract

        params do
          required(:hbx_id).filled(:string)
          optional(:home_page).maybe(:string)
          required(:legal_name).filled(:string)
          optional(:dba).maybe(:string)
          required(:entity_kind).filled(:symbol)
          required(:fein).filled(:string)
          required(:site_id).filled(Types::Bson)
        end
      end
    end
  end
end