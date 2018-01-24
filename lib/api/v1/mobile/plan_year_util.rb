module Api
  module V1
    module Mobile
      class PlanYearUtil < BaseUtil
        MAX_DENTAL_PLANS = 13
        attr_accessor :plan_year

        def is_current_or_upcoming?
          now = TimeKeeper.date_of_record
          (now - 1.year..now + 1.year).include? @plan_year.try(:start_on)
        end

        def open_enrollment?
          employee_max? && @as_of &&
              @plan_year.open_enrollment_start_on &&
              @plan_year.open_enrollment_end_on &&
              @plan_year.open_enrollment_contains?(@as_of)
        end

        def employee_max?
          @plan_year && plan_year_employee_max?
        end

        def plan_offerings
          @plan_year.benefit_groups.compact.map do |benefit_group|
            {benefit_group_name: benefit_group.title,
             eligibility_rule: BenefitGroupUtil.new(benefit_group: benefit_group).eligibility_rule,
             health: health_offering(benefit_group),
             dental: dental_offering(benefit_group)}
          end
        end

        def render_summary
          renewals_offset_in_months = Settings.aca.shop_market.renewal_application.earliest_start_prior_to_effective_on.months

          {
              open_enrollment_begins: @plan_year.open_enrollment_start_on,
              open_enrollment_ends: @plan_year.open_enrollment_end_on,
              plan_year_begins: @plan_year.start_on,
              renewal_in_progress: @plan_year.is_renewing?,
              renewal_application_available: @plan_year.start_on >> renewals_offset_in_months,
              renewal_application_due: @plan_year.due_date_for_publish,
              state: @plan_year.aasm_state.to_s.humanize.titleize,
              minimum_participation_required: @plan_year.minimum_enrolled_count
          }
        end

        def render_details
          summary = render_summary
          summary[:plan_offerings] = plan_offerings
          summary
        end

        #
        # Private
        #
        private

        def dental_offering benefit_group
          render_plan_offering(
              plan: benefit_group.dental_reference_plan,
              plan_option_kind: benefit_group.plan_option_kind,
              relationship_benefits: benefit_group.dental_relationship_benefits,
              employer_estimated_max: benefit_group.monthly_employer_contribution_amount(benefit_group.dental_reference_plan),
              employee_estimated_min: benefit_group.monthly_min_employee_cost('dental'),
              employee_estimated_max: benefit_group.monthly_max_employee_cost('dental'),
              elected_dental_plans: elected_dental_plans(benefit_group)) if benefit_group.is_offering_dental? && benefit_group.dental_reference_plan
        end

        def elected_dental_plans benefit_group
          benefit_group.elected_dental_plans.map do |p|
            {carrier_name: p.carrier_profile.legal_name,
             plan_name: p.name}
          end if benefit_group.elected_dental_plan_ids.count < MAX_DENTAL_PLANS
        end

        def health_offering benefit_group
          render_plan_offering(
              plan: benefit_group.reference_plan,
              plan_option_kind: benefit_group.plan_option_kind,
              relationship_benefits: benefit_group.relationship_benefits,
              employer_estimated_max: benefit_group.monthly_employer_contribution_amount,
              employee_estimated_min: benefit_group.monthly_min_employee_cost,
              employee_estimated_max: benefit_group.monthly_max_employee_cost)
        end

        def render_plan_offering plan: nil, plan_option_kind: nil, relationship_benefits: [], employer_estimated_max: 0,
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

        def render_plans_by! rendered
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

        def display_metal_level plan
          (plan.active_year == 2015 || plan.coverage_kind == 'health' ? plan.metal_level : plan.dental_level).try(:titleize)
        end

        def plan_year_employee_max?
          @plan_year.employer_profile.census_employees.count < 100
        end

      end
    end
  end
end