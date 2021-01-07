# frozen_string_literal: true

module BenefitSponsors
  module Validators
    class AddressContract < Dry::Validation::Contract

      params do
        required(:kind).filled(:string)
        required(:address_1).maybe(:string)
        optional(:address_2).maybe(:string)
        optional(:address_3).maybe(:string)
        required(:city).maybe(:string)
        optional(:county).maybe(:string)
        required(:state).maybe(:string)
        required(:zip).maybe(:string)
        optional(:country_name).maybe(:string)
      end

      rule(:zip) do
        key.failure("#{values[:kind].capitalize} Addresses: zip can't be blank") if values[:zip].to_s.empty?
        key.failure("#{values[:kind].capitalize} Addresses: zip should be in the form: 12345 or 12345-1234") if values[:zip].to_s.present? && !/\A\d{5}(-\d{4})?\z/.match?(value)
      end

      rule(:address_1) do
        key.failure("#{values[:kind].capitalize} Addresses: address 1 can't be blank") if values[:address_1].to_s.empty?
      end

      rule(:city) do
        key.failure("#{values[:kind].capitalize} Addresses: city can't be blank") if values[:city].to_s.empty?
      end

      rule(:state) do
        key.failure("#{values[:kind].capitalize} Addresses: state can't be blank") if values[:state].to_s.empty?
      end

    end
  end
end
