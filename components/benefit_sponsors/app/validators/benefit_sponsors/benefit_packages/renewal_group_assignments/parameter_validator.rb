# frozen_string_literal: true

module BenefitSponsors
  module BenefitPackages
    module RenewalGroupAssignments
      class ParameterValidator < ::BenefitSponsors::BaseParamValidator
        define do
          required(:benefit_package_id).filled(::BenefitSponsors::BsonObjectIdString)
          required(:census_employee_id).filled(::BenefitSponsors::BsonObjectIdString)
          required(:effective_on_date).filter(format?: /\d{4}-\d{2}-\d{2}/).value(:date)
        end
      end
    end
  end
end