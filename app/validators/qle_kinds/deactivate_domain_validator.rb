# frozen_string_literal: true

module QleKinds
  class DeactivateDomainValidator < BenefitSponsors::BaseDomainValidator
    params do
      required(:user).value(:filled?)
      required(:request).value(:filled?)
      required(:service).value(:filled?)
    end

    rule(:request, :service) do
      key(:end_on_present).failure(:end_on_not_present) unless values[:service].end_on_present?(values[:request].end_on)
    end
  end
end
