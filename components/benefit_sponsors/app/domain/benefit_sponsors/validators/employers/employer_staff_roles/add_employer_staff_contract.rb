# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module Employers
      module EmployerStaffRoles
        # Staff Contract is to validate submitted params while persisting staff
        class AddEmployerStaffContract < Dry::Validation::Contract

          params do
            required(:person_id).value(:string)
            required(:first_name).value(:string)
            required(:last_name).value(:string)
            required(:profile_id).value(:string)
            optional(:gender).maybe(:string)
            required(:dob).maybe(:date)
            optional(:area_code).maybe(:string)
            optional(:number).maybe(:string)
            optional(:email).maybe(:string)
            required(:coverage_record).filled(:hash)
          end

          rule(:coverage_record) do
            if key? && value
              if value&.is_a?(Hash)
                result = BenefitSponsors::Validators::Employers::CoverageRecordContract.new.call(value)
                key.failure(text: "invalid coverage_record", error: result.errors.to_h) if result&.failure?
              else
                key.failure(text: "invalid coverage_record. Expected a hash.")
              end
            end
          end
        end
      end
    end
  end
end
