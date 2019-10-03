# frozen_string_literal: true

module QleKinds
  class CreateDomainValidator < BenefitSponsors::BaseDomainValidator
    params do
      required(:user).value(:filled?)
      required(:request).value(:filled?)
      required(:service).value(:filled?)
    end

    rule(:request, :service) do

      key(:duplicate_title).failure(:duplicate_title) unless values[:service].title_is_unique?(values[:request].title)
      # key(:reason_is_invalid).failure(:reason_is_invalid) unless values[:service].reason_is_valid?(values[:request].reason)
      # key(:duplicate_title).failure(:duplicate_title) unless values[:service].post_sep_eligiblity_date_is_valid?(values[:request].post_sep_eligiblity_date)
    end
  end
end
