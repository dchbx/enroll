module Api
  module V1
    class PlanYearHelper < BaseHelper

      MAX_DENTAL_PLANS = 13

      def self.open_enrollment? plan_year, as_of
        self.employee_max?(plan_year) && as_of &&
            plan_year.open_enrollment_start_on &&
            plan_year.open_enrollment_end_on &&
            plan_year.open_enrollment_contains?(as_of)
      end

      def self.employee_max? plan_year
        plan_year && plan_year_employee_max?(plan_year)
      end

      #
      # Private
      #
      private

      def self.plan_offerings plan_year
        plan_year.benefit_groups.compact.map do |benefit_group|
          health_offering = render_plan_offering(
              plan: benefit_group.reference_plan,
              plan_option_kind: benefit_group.plan_option_kind,
              relationship_benefits: benefit_group.relationship_benefits,
              employer_estimated_max: benefit_group.monthly_employer_contribution_amount,
              employee_estimated_min: benefit_group.monthly_min_employee_cost,
              employee_estimated_max: benefit_group.monthly_max_employee_cost)

          elected_dental_plans = benefit_group.elected_dental_plans.map do |p|
            {carrier_name: p.carrier_profile.legal_name,
             plan_name: p.name}
          end if benefit_group.elected_dental_plan_ids.count < MAX_DENTAL_PLANS

          dental_offering = render_plan_offering(
              plan: benefit_group.dental_reference_plan,
              plan_option_kind: benefit_group.plan_option_kind,
              relationship_benefits: benefit_group.dental_relationship_benefits,
              employer_estimated_max: benefit_group.monthly_employer_contribution_amount(benefit_group.dental_reference_plan),
              employee_estimated_min: benefit_group.monthly_min_employee_cost('dental'),
              employee_estimated_max: benefit_group.monthly_max_employee_cost('dental'),
              elected_dental_plans: elected_dental_plans) if benefit_group.is_offering_dental? && benefit_group.dental_reference_plan

          {benefit_group_name: benefit_group.title,
           eligibility_rule: BenefitGroupHelper.eligibility_rule(benefit_group),
           health: health_offering,
           dental: dental_offering}
        end
      end

      def self.render_plan_offering plan: nil, plan_option_kind: nil, relationship_benefits: [], employer_estimated_max: 0,
          employee_estimated_min: 0, employee_estimated_max: 0, elected_dental_plans: nil
        render_plans_by!(
            reference_plan_name: plan.name.try(:upcase),
            reference_plan_HIOS_id: plan.hios_id,
            carrier_name: plan.carrier_profile.try(:legal_name),
            plan_type: plan.try(:plan_type).try(:upcase),
            metal_level: display_metal_level(plan),
            plan_option_kind: plan_option_kind,
            employer_contribution_by_relationship:
                Hash[relationship_benefits.map do |rb|
                  [rb.relationship, rb.offered ? rb.premium_pct : nil]
                end],
            elected_dental_plans: elected_dental_plans,
            estimated_employer_max_monthly_cost: employer_estimated_max,
            estimated_plan_participant_min_monthly_cost: employee_estimated_min,
            estimated_plan_participant_max_monthly_cost: employee_estimated_max
        )
      end

      def self.render_plans_by! rendered
        count_dental_plans = rendered[:elected_dental_plans].try(:count)
        plans_by, plans_by_summary_text =
            case rendered[:plan_option_kind]
              when 'single_carrier'
                ['All Plans From A Single Carrier', "All #{rendered[:carrier_name]} Plans"]
              when 'metal_level'
                ['All Plans From A Given Metal Level', "All #{rendered[:metal_level]} Level Plans"]
              when 'single_plan'
                if count_dental_plans.nil?
                  ['A Single Plan', 'Reference Plan Only']
                else
                  [count_dental_plans < MAX_DENTAL_PLANS ? "Custom (#{ count_dental_plans } Plans)" : 'All Plans'] * 2
                end
            end

        rendered[:plans_by] = plans_by
        rendered[:plans_by_summary_text] = plans_by_summary_text
        rendered
      end

      def self.display_metal_level plan
        (plan.active_year == 2015 || plan.coverage_kind == 'health' ? plan.metal_level : plan.dental_level).try(:titleize)
      end

      def self.plan_year_employee_max? plan_year
        plan_year.employer_profile.census_employees.count < 100
      end

    end
  end
end