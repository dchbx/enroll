# frozen_string_literal: true

module BenefitSponsors
  module BenefitPackages
    module ReinstateEmployeeEnrollments
      # This class checks and validates the incoming params
      class ParameterValidator < ::BenefitSponsors::BaseParamValidator
        define do
          required(:notify).filled(:bool)
          required(:hbx_enrollment_id).filled(::BenefitSponsors::BsonObjectIdString)
          required(:benefit_package_id).filled(::BenefitSponsors::BsonObjectIdString)
        end
      end
    end
  end
end