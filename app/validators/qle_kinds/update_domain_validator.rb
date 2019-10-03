# frozen_string_literal: true

module QleKinds
  class UpdateDomainValidator < BenefitSponsors::BaseDomainValidator
    params do
      required(:user).value(:filled?)
      required(:request).value(:filled?)
      required(:service).value(:filled?)
    end

    rule(:request, :service) do

      key(:reason_is_invalid).failure(:reason_is_invalid) unless values[:service].reason_is_valid?(values[:request].reason)
    end
  end
end
