# frozen_string_literal: true

module BenefitSponsors
  module BenefitPackages
    module ReinstateGroupAssignments
      # This class checks and validates the incoming params
      class ParameterValidator < ::BenefitSponsors::BaseParamValidator
        define do
          required(:benefit_package_id).filled(::BenefitSponsors::BsonObjectIdString)
          required(:census_employee_id).filled(::BenefitSponsors::BsonObjectIdString)
          required(:benefit_group_assignment_id).filled(::BenefitSponsors::BsonObjectIdString)
        end
      end
    end
  end
end