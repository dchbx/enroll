# frozen_string_literal: true
module BenefitSponsors
  module Entities
    module Employers
      module EmployerStaffRoles
        # Create a object with coverage record values
        class CoverageRecord < Dry::Struct
          transform_keys(&:to_sym)

          attribute :ssn, Types::String.optional
          attribute :dob, Types::Date.optional
          attribute :hired_on, Types::Date.optional
          attribute :gender, Types::String.optional
          attribute :is_applying_coverage, Types::Bool
          attribute :address, BenefitSponsors::Entities::Address.optional
          attribute :email, BenefitSponsors::Entities::Email.optional
        end
      end
    end
  end
end