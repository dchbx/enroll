# frozen_string_literal: true

module BenefitSponsors
  module BrokerAgencyRegistration
    module CreateRequestValidators
      class PARAMS < ::BenefitSponsors::BaseParamValidator
        define do
          required(:legal_name).value(:filled?)
          optional(:dba).maybe(:str?)
          required(:first_name).value(:filled?)
          required(:last_name).value(:filled?)
          required(:npn).value(:filled?)
          required(:dob).value(:us_date?)
          required(:email).value(:filled?, :email?)
          required(:practice_area).value(:filled?)
          required(:accepts_new_clients).filled(::Dry::Types["params.bool"])
          required(:evening_weekend_hours).filled(::Dry::Types["params.bool"])

          required(:phone).schema(BenefitSponsors::ContactInformation::PhoneValidators::PARAMS)

          required(:address).schema(BenefitSponsors::Locations::AddressValidators::PARAMS)

          required(:languages).value(:array?, min_size?: 1)

          optional(:office_locations).array(BenefitSponsors::Locations::OfficeLocationValidators::PARAMS)
        end
      end

      class DOMAIN < ::BenefitSponsors::BaseDomainValidator
        schema do
          required(:user).value(:filled?)
          required(:request).value(:filled?)
        end

        rule(:user, :request) do |_user, _request|
          key(:broker_person_identity_available).failure(:broker_person_identity_available) unless BenefitSponsors::Services::BrokerRegistrationService.may_claim_broker_identity?(values[:user], values[:request])
        end

        rule(:request) do
          too_many_mailing_addresses = value.office_locations.many? do |ol|
            ol.kind == "mailing"
          end
          key(:only_one_mailing_office_location).failure(:only_one_mailing_office_location) if too_many_mailing_addresses
        end
      end
    end
  end
end