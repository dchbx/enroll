module Api
  module V1
    class StaffHelper < BaseHelper

      # Returns a hash of arrays of staff members, keyed by employer id
      def by_employer_id
        result = {}
        @members.each { |staff|
          staff.employer_staff_roles.each { |role|
            result[role.employer_profile_id].nil? ? result[role.employer_profile_id] = [staff] :
                result[role.employer_profile_id] <<= staff
          }
        }
        result.compact
      end

    end
  end
end