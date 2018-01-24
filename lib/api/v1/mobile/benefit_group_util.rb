module Api
  module V1
    module Mobile
      class BenefitGroupUtil < BaseUtil
        attr_accessor :ids, :plan_year

        def initialize args
          super args
          @ids = @plan_year.benefit_groups.map(&:id) if @plan_year
        end

        def employees
          CensusMember.where(
              {"benefit_group_assignments.benefit_group_id" => {"$in" => @ids},
               :aasm_state => {'$in' => ['eligible', 'employee_role_linked']}
              })
        end

        def eligibility_rule
          case @benefit_group.effective_on_offset
            when 0
              'First of the month following or coinciding with date of hire'
            when 1
              'First of the month following date of hire'
            else
              "#{@benefit_group.effective_on_kind.humanize} following #{@benefit_group.effective_on_offset} days"
          end
        end

      end
    end
  end
end