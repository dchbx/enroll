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
          required(:profiles).value(:array)
        end

        rule(:profiles).each do
          next unless key? && value

          profile_types = [::BenefitSponsors::Entities::Profiles::AcaShopDcEmployerProfile, ::BenefitSponsors::Entities::Profiles::GeneralAgencyProfile, ::BenefitSponsors::Entities::Profiles::BrokerAgencyProfile]
          next if profile_types.include?(value.class)

          if value.is_a?(Hash)
            result = BenefitSponsors::Validators::Profiles::ProfileContract.new.call(value)
            key.failure(text: "invalid profile", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "invalid profile. Expected a hash profile entity")
          end
        end
      end
    end
  end
end