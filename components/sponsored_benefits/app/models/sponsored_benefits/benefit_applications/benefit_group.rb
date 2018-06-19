module SponsoredBenefits
  module BenefitApplications
    class BenefitGroup < ::BenefitGroup
      embedded_in :benefit_application
      delegate :effective_period, to: :benefit_application
      delegate :sic_code, to: :benefit_application
      delegate :rating_area, to: :benefit_application
      delegate :census_employees, to: :benefit_application
      delegate :plan_design_organization, to: :benefit_application

      def targeted_census_employees
        target_object = persisted? ? benefit_application.benefit_sponsorship : benefit_application.benefit_sponsorship
        target_object.census_employees
      end

      def employer_profile
        plan_design_organization
      end

      def plan_year
        OpenStruct.new(
          :start_on => effective_period.begin,
          :sic_code => sic_code,
          :rating_area => rating_area,
          :estimate_group_size? => true
        )
      end

      def employee_costs_for_reference_plan
          plan = reference_plan
          employee_costs = census_employees.active.inject({}) do |census_employees, employee|
            costs = {
              ref_plan_cost: employee_cost_for_plan(employee, plan)
            }

            if !single_plan_type?
              costs.merge!({
                lowest_plan_cost: employee_cost_for_plan(employee, lowest_cost_plan),
                highest_plan_cost: employee_cost_for_plan(employee, highest_cost_plan)
                })
            end
            census_employees[employee.id] = costs
            census_employees
          end

          employee_costs.merge!({
            ref_plan_employer_cost: monthly_employer_contribution_amount(plan),
            lowest_plan_employer_cost: monthly_employer_contribution_amount(lowest_cost_plan),
            highest_plan_employer_cost: monthly_employer_contribution_amount(highest_cost_plan)
            })
      end

      def lowest_cost_plan
        @lowest_cost_plan ||= ::Plan.find(lowest_cost_plan_id)
      end

      def highest_cost_plan
        @highest_cost_plan ||= ::Plan.find(highest_cost_plan_id)
      end

    end
  end
end
