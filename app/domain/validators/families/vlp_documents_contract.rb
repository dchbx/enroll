# frozen_string_literal: true

module Validators
  module Families
    class VlpDocumentContract < Dry::Validation::Contract
      params do

        optional(:subject).maybe(:string)
        optional(:alien_number).maybe(:string)
        optional(:i94_number).maybe(:string)
        optional(:visa_number).maybe(:string)
        optional(:passport_number).maybe(:string)
        optional(:sevis_id).maybe(:string)
        optional(:naturalization_number).maybe(:string)
        optional(:receipt_number).maybe(:string)
        optional(:citizenship_number).maybe(:string)
        optional(:card_number).maybe(:string)
        optional(:country_of_citizenship).maybe(:string)
        optional(:expiration_date).maybe(:date)
        optional(:issuing_country).maybe(:string)

      end
    end
  end
end