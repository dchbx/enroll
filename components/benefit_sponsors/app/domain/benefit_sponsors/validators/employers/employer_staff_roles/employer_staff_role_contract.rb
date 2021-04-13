# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module Employers
      module EmployerStaffRoles
        # Staff Contract is to validate employer staff record
        class EmployerStaffRoleContract < Dry::Validation::Contract
          params do
            required(:is_owner).filled(:bool)
            required(:aasm_state).filled(:string)
            required(:benefit_sponsor_employer_profile_id).filled(Types::Bson)
            required(:coverage_record).filled(:hash)
          end

          rule(:coverage_record) do
            if key? && value
              if value.is_a?(Hash)
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
