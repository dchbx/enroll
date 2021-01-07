# frozen_string_literal: true

module BenefitSponsors
  module Entities
    module Employers
      module EmployerStaffRoles
        # Create a object with Employer staff role values
        class EmployerStaffRole < Dry::Struct
          transform_keys(&:to_sym)

          attribute :is_owner, Types::Bool
          attribute :aasm_state, Types::String
          attribute :benefit_sponsor_employer_profile_id, Types::Bson
          attribute :coverage_record, BenefitSponsors::Entities::Employers::EmployerStaffRoles::CoverageRecord
        end
      end
    end
  end
end
