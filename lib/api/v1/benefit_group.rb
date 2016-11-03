require_relative 'base'

module Api
  module V1
    class BenefitGroup < Base

      def initialize args
        super args
        @ids = plan_year.benefit_groups.map(&:id)
      end

      def employees
        CensusMember.where(
            {"benefit_group_assignments.benefit_group_id" => {"$in" => @ids},
             :aasm_state => {'$in' => ['eligible', 'employee_role_linked']}
            })
      end

    end
  end
end