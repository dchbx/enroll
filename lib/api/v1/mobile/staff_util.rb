module Api
  module V1
    module Mobile
      class StaffUtil < BaseUtil

        # Returns a hash of arrays of staff members, keyed by employer id
        def keyed_by_employer_id
          result = {}
          people.each { |staff|
            staff.employer_staff_roles.each { |role|
              result[role.employer_profile_id].nil? ? result[role.employer_profile_id] = [staff] :
                  result[role.employer_profile_id] <<= staff
            }
          }
          result.compact
        end

        #
        # Private
        #
        private

        def people
          Person.where(:employer_staff_roles => {
              '$elemMatch' => {
                  employer_profile_id: {"$in": @employer_profiles.map(&:id)},
                  :aasm_state.ne => :is_closed
              }
          })
        end

      end
    end
  end
end