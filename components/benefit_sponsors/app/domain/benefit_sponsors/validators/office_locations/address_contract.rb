# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module OfficeLocations
      # Address Contract is to validate submitted params while persisting Address
      class AddressContract < Dry::Validation::Contract

        params do
          required(:kind).filled(:string)
          required(:address_1).maybe(:string)
          optional(:address_2).maybe(:string)
          required(:city).maybe(:string)
          required(:state).maybe(:string)
          required(:zip).maybe(:string)
        end

        rule(:zip) do
          key.failure("#{values[:kind].capitalize} Addresses: zip can't be blank") if value.empty?
          key.failure("#{values[:kind].capitalize} Addresses: zip should be in the form: 12345") if value.present? && !/\A[0-9][0-9][0-9][0-9][0-9]\z/.match?(value) && rule_error?
        end

        rule(:address_1) do
          key.failure("#{values[:kind].capitalize} Addresses: address 1 can't be blank") if value.empty?
        end

        rule(:city) do
          key.failure("#{values[:kind].capitalize} Addresses: city can't be blank") if value.empty?
        end

        rule(:state) do
          key.failure("#{values[:kind].capitalize} Addresses: state can't be blank") if value.empty?
          key.failure('Invalid state') unless State::NAME_IDS.map(&:last).include?(value) && !rule_error?
        end
      end
    end
  end
end
