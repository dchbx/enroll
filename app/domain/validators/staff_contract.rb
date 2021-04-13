# frozen_string_literal: true

module Validators
  # Staff Contract is to validate inital & submitted params while initalizing/persisting staff
  class StaffContract < Dry::Validation::Contract

    params do
      required(:person_id).value(:string)
      required(:first_name).value(:string)
      required(:last_name).value(:string)
      optional(:profile_id).value(:string)
      optional(:gender).maybe(:string)
      optional(:dob).maybe(:date)
      optional(:area_code).maybe(:string)
      optional(:number).maybe(:string)
      optional(:email).maybe(:string)
      optional(:coverage_record).schema do
        optional(:ssn).maybe(:string)
        optional(:dob).maybe(:date)
        optional(:hired_on).maybe(:date)
        optional(:gender).maybe(:string)
        required(:is_applying_coverage).value(:bool)
        required(:address).maybe(:hash)
        required(:email).maybe(:hash)
      end
    end

    rule(:coverage_record) do
      if key? && value && value[:is_applying_coverage]
        address = value[:address]
        email = value[:email]
        if address.is_a?(Hash)
          result = Validators::AddressContract.new.call(address)
          key.failure(text: "invalid address", error: result.errors.to_h) if result&.failure?
        else
          key.failure(text: "invalid addresses. Expected a hash.")
        end

        if email.is_a?(Hash)
          result = Validators::EmailContract.new.call(email)
          key.failure(text: "invalid email", error: result.errors.to_h) if result&.failure?
        else
          key.failure(text: "invalid emails. Expected a hash.")
        end
      end
    end
  end
end
