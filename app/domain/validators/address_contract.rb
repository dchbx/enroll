# frozen_string_literal: true

module Validators
  class AddressContract < Dry::Validation::Contract

    params do
      required(:kind).maybe(:string)
      required(:address_1).maybe(:string)
      optional(:address_2).maybe(:string)
      optional(:address_3).maybe(:string)
      required(:city).maybe(:string)
      optional(:county).maybe(:string)
      required(:state).maybe(:string)
      required(:zip).maybe(:string)
      optional(:country_name).maybe(:string)
    end
  end
end