# frozen_string_literal: true

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

      def employee_costs_for_reference_plan(service, plan = reference_plan)
        plan.dental? ? set_bounding_cost_dental_plans : set_bounding_cost_plans
        service.employee_cost_for_plan(plan) # To initialize census_employee_costs
        unless single_plan_type?
          service.employee_cost_for_plan(lowest_cost_plan)
          service.employee_cost_for_plan(highest_cost_plan)
        end
        employee_costs = census_employees.active.inject({}) do |census_employees, employee|
          costs = {
            ref_plan_cost: service.census_employee_costs[plan.id][employee.id]
          }

          unless single_plan_type?
            costs.merge!({
                           lowest_plan_cost: service.census_employee_costs[lowest_cost_plan.id][employee.id],
                           highest_plan_cost: service.census_employee_costs[highest_cost_plan.id][employee.id]
                         })
          end
          census_employees[employee.id] = costs
          census_employees
        end

        employee_costs.merge!({
                                ref_plan_employer_cost: service.monthly_employer_contribution_amount(plan),
                                lowest_plan_employer_cost: service.monthly_employer_contribution_amount(lowest_cost_plan),
                                highest_plan_employer_cost: service.monthly_employer_contribution_amount(highest_cost_plan)
                              })
      end

      def employee_costs_for_dental_reference_plan(service)
        plan = dental_reference_plan
        service.employee_cost_for_plan(plan) # To initialize census_employee_costs
        employee_costs = census_employees.active.inject({}) do |census_employees, employee|
          census_employees[employee.id] = {
            ref_plan_cost: service.census_employee_costs[plan.id][employee.id]
          }
          census_employees
        end

        employee_costs.merge!({
                                ref_plan_employer_cost: service.monthly_employer_contribution_amount(plan)
                              })
      end

      def employee_cost_for_plan(ce, plan = reference_plan)
        pcd = if @is_congress
                decorated_plan(plan, ce)
              elsif plan_option_kind == 'sole_source' && !plan.dental?
                CompositeRatedPlanCostDecorator.new(plan, self, effective_composite_tier(ce), ce.is_cobra_status?)
              else
                if plan.dental? && dental_reference_plan.present?
                  PlanCostDecorator.new(plan, ce, self, dental_reference_plan)
                else
                  PlanCostDecorator.new(plan, ce, self, reference_plan)
                end
        end
        pcd.total_employee_cost
      end

      def lowest_cost_plan
        @lowest_cost_plan ||= ::Plan.find(lowest_cost_plan_id)
      end

      def highest_cost_plan
        @highest_cost_plan ||= ::Plan.find(highest_cost_plan_id)
      end

      def monthly_employer_contribution_amount(plan = reference_plan)
        return 0 if targeted_census_employees.count > 199
        is_dental = self.persisted? && plan.present? && plan.coverage_kind == "dental"
        rp = is_dental ? dental_reference_plan : reference_plan

        if self.sole_source? && self.composite_tier_contributions.empty?
          build_composite_tier_contributions
          estimate_composite_rates
        end
        targeted_census_employees.active.collect do |ce|

          pcd = if plan_option_kind == 'sole_source' && plan.coverage_kind == "health"
                  CompositeRatedPlanCostDecorator.new(plan, self, effective_composite_tier(ce), ce.is_cobra_status?)
                else
                  PlanCostDecorator.new(plan, ce, self, rp)
                end
          pcd.total_employer_contribution
        end.sum
      end

      def monthly_employee_cost(coverage_kind = nil)
        rp = coverage_kind == "dental" ? dental_reference_plan : reference_plan
        return [0] if targeted_census_employees.count > 199
        targeted_census_employees.active.collect do |ce|
          pcd = if self.sole_source? && !rp.dental?
                  CompositeRatedPlanCostDecorator.new(rp, self, effective_composite_tier(ce), ce.is_cobra_status?)
                else
                  pcd = PlanCostDecorator.new(rp, ce, self, rp)
          end
          pcd.total_employee_cost
        end
      end

      def monthly_min_employee_cost(coverage_kind = nil)
        monthly_employee_cost(coverage_kind).min
      end

      def monthly_max_employee_cost(coverage_kind = nil)
        monthly_employee_cost(coverage_kind).max
      end

      def set_bounding_cost_plans
        return if reference_plan_id.nil?

        if reference_plan.dental?
          set_bounding_cost_dental_plans
          return
        end

        if offerings_constrained_to_service_areas?
          profile_and_service_area_pairs = CarrierProfile.carrier_profile_service_area_pairs_for(self.employer_profile, reference_plan.active_year)
          single_carrier_pair = profile_and_service_area_pairs.select { |pair| pair.first == reference_plan.carrier_profile.id }
        end

        if plan_option_kind == "single_plan"
          plans = [reference_plan]
        elsif plan_option_kind == "sole_source"
          plans = [reference_plan]
        else
          if plan_option_kind == "single_carrier"
            plans = if offerings_constrained_to_service_areas?
                      Plan.for_service_areas_and_carriers(single_carrier_pair, start_on.year).shop_market.check_plan_offerings_for_single_carrier.health_coverage.and(hios_id: /-01/)
                    else
                      Plan.shop_health_by_active_year(reference_plan.active_year).by_carrier_profile(reference_plan.carrier_profile).with_enabled_metal_levels
                    end
          else
            plans = if offerings_constrained_to_service_areas?
                      Plan.for_service_areas_and_carriers(profile_and_service_area_pairs, start_on.year).shop_market.check_plan_offerings_for_metal_level.health_coverage.by_metal_level(reference_plan.metal_level).and(hios_id: /-01/).with_enabled_metal_levels
                    else
                      Plan.shop_health_by_active_year(reference_plan.active_year).by_health_metal_levels([reference_plan.metal_level])
                    end
          end
        end

        set_lowest_and_highest(plans)
      end

      def set_bounding_cost_dental_plans
        return if reference_plan_id.nil?
        option_kind = self.persisted? || dental_plan_option_kind.present? ? dental_plan_option_kind : plan_option_kind
        if option_kind == "single_plan"
          plans = elected_dental_plans
        elsif option_kind == "single_carrier"
          ref_plan = self.persisted? || dental_reference_plan.present? ? dental_reference_plan : reference_plan
          plans = Plan.shop_dental_by_active_year(ref_plan.active_year).by_carrier_profile(ref_plan.carrier_profile)
        end

        set_lowest_and_highest(plans)
      end

      def set_lowest_and_highest(plans)
        unless plans.empty?
          plans = plans.select{|a| a.premium_tables.present?}
          plans_by_cost = plans.sort_by { |plan| plan.premium_tables.first.cost }

          self.lowest_cost_plan_id = plans_by_cost.first.id
          @lowest_cost_plan = plans_by_cost.first

          self.highest_cost_plan_id = plans_by_cost.last.id
          @highest_cost_plan = plans_by_cost.last
        end
      end

      def elected_dental_plans=(new_plans)
        return unless new_plans.present?
        self.elected_dental_plan_ids = if parsed_dental_elected_plan_ids(new_plans).is_a?(Array) && new_plans.is_a?(String)
                                         parsed_dental_elected_plan_ids(new_plans)
                                       else
                                         new_plans.reduce([]) { |list, plan| list << plan._id }
                                       end
      end

      def parsed_dental_elected_plan_ids(new_plans)
        return @result if defined? @result
        @result = begin
          JSON.parse(new_plans)
                  rescue Exception => e
                    new_plans.split(" ")
        end
      end

      def dental_single_plan_type?
        dental_plan_option_kind == "single_plan"
      end
    end
  end
end
