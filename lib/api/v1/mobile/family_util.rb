module Api
  module V1
    module Mobile
      class FamilyUtil < BaseUtil

        def hbx_enrollments
          families = Family.where(:'households.hbx_enrollments'.elem_match => {
              :'benefit_group_assignment_id'.in => @benefit_group_assignment_ids,
              :aasm_state.in => @aasm_states,
              :kind => 'employer_sponsored',
              :coverage_kind => 'health',
              :is_active => true
          })

          families.map { |f| f.households.map { |h| h.hbx_enrollments } }.flatten.compact
        end

      end
    end
  end
end