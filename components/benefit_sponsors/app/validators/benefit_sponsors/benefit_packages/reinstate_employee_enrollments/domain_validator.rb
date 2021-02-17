# frozen_string_literal: true

module BenefitSponsors
  module BenefitPackages
    module ReinstateEmployeeEnrollments
      # This class checks and validates the incoming params
      # that are required to build a new Enrollment object,
      # if any of the checks or rules fail it returns a failure in async workflow.
      class DomainValidator < ::BenefitSponsors::BaseDomainValidator
        schema do
          required(:benefit_package_id).value(:filled?)
          required(:hbx_enrollment_id).value(:filled?)
          required(:notify).value(:filled?)
        end

        rule(:benefit_package_id) do
          bp_found = begin
            bp = BenefitSponsors::BenefitPackages::BenefitPackage.find(values[:benefit_package_id])
            bp.present?
          rescue StandardError
            false
          end
          key.failure(:not_found) unless bp_found
        end

        rule(:hbx_enrollment_id) do
          hbx_found = begin
            hbx = HbxEnrollment.find(values[:hbx_enrollment_id])
            hbx.present?
          rescue StandardError
            false
          end
          key.failure(:not_found) unless hbx_found
        end
      end
    end
  end
end