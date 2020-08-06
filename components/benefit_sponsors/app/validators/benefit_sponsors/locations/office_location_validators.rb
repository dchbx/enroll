# frozen_string_literal: true

module BenefitSponsors
  module Locations
    module OfficeLocationValidators
      PARAMS = Dry::Schema.Params do
        required(:kind).value(:filled?, included_in?: ["mailing", "branch"])
        required(:phone).schema(BenefitSponsors::ContactInformation::PhoneValidators::PARAMS)
        required(:address).schema(BenefitSponsors::Locations::AddressValidators::PARAMS)
      end
    end
  end
end