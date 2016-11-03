require_relative 'base'

module Api
  module V1
    class Employee < Base

      def self.benefit_group_assignments benefit_group
        benefit_group.employees.map do |ee|
          ee.benefit_group_assignments.select do |bga|
            benefit_group.ids.include?(bga.benefit_group_id) &&
                (PlanYear::RENEWING_PUBLISHED_STATE.include?(benefit_group.plan_year.aasm_state) || bga.is_active)
          end
        end.flatten
      end

    end
  end
end