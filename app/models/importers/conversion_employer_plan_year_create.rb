module Importers
  class ConversionEmployerPlanYearCreate < ConversionEmployerPlanYear

    def map_plan_year
      employer = find_employer
      found_carrier = find_carrier
      plan_year_attrs = Factories::PlanYearFactory.default_dates_for_coverage_starting_on(calculated_coverage_start)
      plan_year_attrs[:fte_count] = enrolled_employee_count
      plan_year_attrs[:employer_profile] = employer
      plan_year_attrs[:benefit_groups] = [map_benefit_group(found_carrier)]
      # plan_year_attrs[:imported_plan_year] = true
      plan_year_attrs[:aasm_state] = "active"
      plan_year_attrs[:is_conversion] = true
      PlanYear.new(plan_year_attrs)
    end

    def map_benefit_group(found_carrier)
      available_plans = Plan.valid_shop_health_plans("carrier", found_carrier.id, (calculated_coverage_start).year).compact
      begin
        reference_plan = select_reference_plan(available_plans)
        elected_plan_ids = (plan_selection == "single_plan") ? [reference_plan.id] : available_plans.map(&:id)
        benefit_group_properties = {
          :title => "Standard",
          :plan_option_kind => plan_selection,
        :relationship_benefits => map_relationship_benefits,
        :reference_plan_id => reference_plan.id,
        :elected_plan_ids => elected_plan_ids
      }
      if !new_coverage_policy_value.blank?
         benefit_group_properties[:effective_on_offset] = new_coverage_policy_value.offset
         benefit_group_properties[:effective_on_kind] = new_coverage_policy_value.kind
      end
      BenefitGroup.new(benefit_group_properties)
      rescue => e
        puts available_plans.inspect
        raise e
      end
    end

    def map_relationship_benefits
      BenefitGroup::PERSONAL_RELATIONSHIP_KINDS.map do |rel|
        RelationshipBenefit.new({
          :relationship => rel,
          :offered => true,
          :premium_pct => 50.00
        })
      end
    end

    def save
      return false unless valid?
      record = map_plan_year
      save_result = record.save
      propagate_errors(record)
      if save_result
        employer = find_employer
        begin
          employer.update_attributes!(:aasm_state => "enrolled", :profile_source => "conversion")
        rescue Exception => e
          raise "\n#{employer.fein} - #{employer.legal_name}\n#{e.inspect}\n- #{e.backtrace.join("\n")}"
        end
        map_employees_to_benefit_groups(employer, record)
      end
      return save_result
    end
  end
end
