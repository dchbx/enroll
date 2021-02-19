# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module Organizations
      module OrganizationForms
        #Contract is to validate submitted params of staff role (ER, BR, GA)
        class StaffRoleFormContract < Dry::Validation::Contract

          params do
            required(:profile_type).filled(:string)
            required(:first_name).filled(:string)
            optional(:person_id).filled(:string)
            required(:last_name).filled(:string)
            required(:email).filled(:string)
            required(:dob).filter(format?: %r{\d{2}/\d{2}/\d{4}}).value(:string)
            optional(:npn).maybe(:string)
            optional(:coverage_record).maybe(:hash)
          end

          rule(:npn) do
            key.failure('Please enter NPN') if %w[broker_agency general_agency].include?(values[:profile_type]) && value.blank?
            key.failure("npn length can't be more than 10") if values[:profile_type] == 'broker_agency' && value.present? && value.length > 10 && rule_error?
          end

          rule(:coverage_record) do
            if key? && value && values[:profile_type] == 'benefit_sponsor'
              result = BenefitSponsors::Validators::Organizations::OrganizationForms::CoverageRecordFormContract.new.call(value)
              key.failure(text: "invalid coverage record params", error: result.errors.to_h) if result&.failure?
            end
          end
        end
      end
    end
  end
end
