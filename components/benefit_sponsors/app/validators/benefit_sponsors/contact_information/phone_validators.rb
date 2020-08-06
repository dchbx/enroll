# frozen_string_literal: true

module BenefitSponsors
  module ContactInformation
    module PhoneValidators
      PARAMS = Dry::Schema.Params do
        required(:phone_area_code).value(:filled?, format?: /\A[0-9][0-9][0-9]\z/)
        required(:phone_number).value(:filled?, format?: /\A[0-9][0-9][0-9][0-9][0-9][0-9][0-9]\z/)
        optional(:phone_extension).maybe(:filled?, format?: /\Ax?[0-9]+\z/i)
      end
    end
  end
end