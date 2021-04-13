# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module Organizations
      module OrganizationForms
        #Contract is to validate submitted params for coverage record creation under staff role (er, br, ga poc)
        class CoverageRecordFormContract < Dry::Validation::Contract

          params do
            optional(:ssn).maybe(:string)
            optional(:dob).filter(format?: %r{\d{2}/\d{2}/\d{4}}).maybe(:string)
            optional(:gender).maybe(:string)
            optional(:hired_on).maybe(:string)
            required(:is_applying_coverage).filled(:bool)
            optional(:address).maybe(:hash)
            optional(:email).maybe(:hash)
          end


          rule(:ssn) do
            key.failure('Please enter SSN') if key? && values[:is_applying_coverage] == true && value.blank?
          end

          rule(:gender) do
            key.failure('Please enter gender') if key? && values[:is_applying_coverage] == true && value.blank?
          end

          rule(:hired_on) do
            key.failure('Please enter hired on') if key? && values[:is_applying_coverage] == true && value.blank?
            key.failure('Invalid Hired on') if key? && values[:is_applying_coverage] == true && !/\d{4}-\d{2}-\d{2}/.match?(value)
          end

          rule(:address) do
            if key? && values[:is_applying_coverage] == true
              result = BenefitSponsors::Validators::AddressContract.new.call(value)
              key.failure(text: "invalid address in staff role form", error: result.errors.to_h) if result&.failure?
            end
          end

          rule(:email) do
            if key? && values[:is_applying_coverage] == true
              result = BenefitSponsors::Validators::EmailContract.new.call(value)
              key.failure(text: "invalid email in staff role form", error: result.errors.to_h) if result&.failure?
            end
          end
        end
      end
    end
  end
end
