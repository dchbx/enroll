# frozen_string_literal: true

module Validators
  class PhoneContract < Dry::Validation::Contract

    params do
      required(:kind).maybe(:string)
      optional(:country_code).maybe(:string)
      optional(:area_code).maybe(:string)
      optional(:number).maybe(:string)
      optional(:extension).maybe(:string)
      required(:full_phone_number).maybe(:string)
      optional(:primary).maybe(:bool)
    end
  end
end
