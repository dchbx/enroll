# frozen_string_literal: true

module Validators
  class PersonContract < Dry::Validation::Contract

    params do
      optional(:hbx_id).maybe(:string)
      optional(:name_pfx).maybe(:string)
      required(:first_name).maybe(:string)
      optional(:middle_name).maybe(:string)
      required(:last_name).maybe(:string)
      optional(:name_sfx).maybe(:string)
      optional(:ssn).maybe(:string)
      required(:gender).maybe(:string)
      required(:dob).filled(:date)

      required(:is_incarcerated).filled(:bool)
      optional(:is_disabled).filled(:bool)
      optional(:ethnicity).maybe(:array)
      optional(:race).maybe(:string)
      optional(:indian_tribe_member).filled(:bool)
      optional(:tribal_id).maybe(:string)

      optional(:language_code).maybe(:string)
      optional(:no_dc_address).filled(:bool)
      optional(:is_homeless).maybe(:bool)
      optional(:is_temporarily_out_of_state).maybe(:bool)

      optional(:no_ssn).maybe(:string)
      required(:same_with_primary).filled(:bool)

      optional(:addresses).maybe(:array)
      optional(:phones).maybe(:array)
      optional(:emails).maybe(:array)
    end

    rule(:addresses).each do
      if key? && value
        if value.is_a?(Hash)
          result = Validators::AddressContract.new.call(value)
          key.failure(text: "invalid address", error: result.errors.to_h) if result&.failure?
        else
          key.failure(text: "invalid addresses. Expected a hash.")
        end
      end
    end

    rule(:phones).each do
      if key? && value
        if value.is_a?(Hash)
          result = Validators::PhoneContract.new.call(value)
          key.failure(text: "invalid phone", error: result.errors.to_h) if result&.failure?
        else
          key.failure(text: "invalid phones. Expected a hash.")
        end
      end
    end

    rule(:emails).each do
      if key? && value
        if value.is_a?(Hash)
          result = Validators::EmailContract.new.call(value)
          key.failure(text: "invalid email", error: result.errors.to_h) if result&.failure?
        else
          key.failure(text: "invalid emails. Expected a hash.")
        end
      end
    end
  end
end