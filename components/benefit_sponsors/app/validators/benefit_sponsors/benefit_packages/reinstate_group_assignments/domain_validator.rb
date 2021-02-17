# frozen_string_literal: true

module BenefitSponsors
  module BenefitPackages
    module ReinstateGroupAssignments
      # This class checks and validates the incoming params
      # that are required to build a new assignment object,
      # if any of the checks or rules fail it returns a failure in async workflow.
      class DomainValidator < ::BenefitSponsors::BaseDomainValidator
        schema do
          required(:benefit_package_id).value(:filled?)
          required(:census_employee_id).value(:filled?)
          required(:benefit_group_assignment_id).value(:filled?)
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

        rule(:census_employee_id) do
          ce_found = begin
            ce = CensusEmployee.find(values[:census_employee_id])
            ce.present?
          rescue StandardError
            false
          end
          key.failure(:not_found) unless ce_found
        end

        rule(:benefit_group_assignment_id) do
          bga_found = begin
            ce = CensusEmployee.find(values[:census_employee_id])
            ce.benefit_group_assignments.find(values[:benefit_group_assignment_id]).present?
          rescue StandardError
            false
          end
          key.failure(:not_found) unless bga_found
        end
      end
    end
  end
end