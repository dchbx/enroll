# frozen_string_literal: true

module BenefitSponsors
  module BenefitPackages
    module EmployeeRenewals
      class ParameterValidator < ::BenefitSponsors::BaseParamValidator
        define do
          required(:benefit_package_id).filled(::BenefitSponsors::BsonObjectIdString)
          required(:census_employee_id).filled(::BenefitSponsors::BsonObjectIdString)
        end
      end
    end
  end
end