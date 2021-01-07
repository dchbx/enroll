# frozen_string_literal: true

module Validators
  module Employers
    # Staff Contract is to validate inital & submitted params while initalizing/persisting staff
    class EmployerStaffRoleContract < Dry::Validation::Contract

      params do
        required(:is_owner).filled(:bool)
        required(:benefit_sponsor_employer_profile_id).filled(Types::Bson)
        required(:coverage_record).filled(:hash)
      end

      rule(:coverage_record) do
        if key? && value && value[:is_applying_coverage]
          address = value[:address]
          email = value[:email]
          if address&.is_a?(Hash)
            result = Validators::AddressContract.new.call(address)
            key.failure(text: "invalid address", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "invalid addresses. Expected a hash.")
          end

          if email&.is_a?(Hash)
            result = Validators::EmailContract.new.call(email)
            key.failure(text: "invalid email", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "invalid emails. Expected a hash.")
          end
        end
      end
    end
  end
end
