# frozen_string_literal: true

module BenefitSponsors
  module BenefitPackages
    module RenewalGroupAssignments
      class DomainValidator < ::BenefitSponsors::BaseDomainValidator
        schema do
          required(:benefit_package_id).value(:filled?)
          required(:census_employee_id).value(:filled?)
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
      end
    end
  end
end