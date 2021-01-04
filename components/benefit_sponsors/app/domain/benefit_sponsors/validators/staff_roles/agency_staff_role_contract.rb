# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module StaffRoles
      # Agency Staff Role Contract is to validate submitted params while persisting agency staff role
      class AgencyStaffRoleContract < Dry::Validation::Contract

        params do
          required(:first_name).value(:string)
          required(:last_name).value(:string)
          required(:dob).filled(:date)
          required(:email).filled(:string)
          required(:npn).filled(:integer)
        end

        rule(:npn) do
          key.failure("#{values[:kind].capitalize} Staff: npn length can't be blank") if values[:npn].to_s.empty?
          key.failure("#{values[:kind].capitalize} Staff: npn length can't be more than 10") if values[:npn].to_s.length > 10
        end
      end
    end
  end
end
