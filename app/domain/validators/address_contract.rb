# frozen_string_literal: true

module Validators
  class AddressContract < Dry::Validation::Contract

    params do
      required(:kind).filled(:string)
      required(:address_1).filled(:string)
      optional(:address_2).maybe(:string)
      optional(:address_3).maybe(:string)
      required(:city).filled(:string)
      optional(:county).maybe(:string)
      required(:state).filled(:string)
      required(:zip).filled(:string)
      optional(:country_name).maybe(:string)
    end
  end
end