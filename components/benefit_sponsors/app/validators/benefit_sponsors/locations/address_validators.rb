# frozen_string_literal: true

module BenefitSponsors
  module Locations
    module AddressValidators
      PARAMS = Dry::Schema.Params do
        required(:address_1).value(:filled?)
        optional(:address_2).maybe(:str?)
        required(:city).value(:filled?)
        required(:state).value(included_in?: State::NAME_IDS.map(&:last))
        required(:zip).value(:filled?, format?: /\A[0-9][0-9][0-9][0-9][0-9]\z/)
      end
    end
  end
end