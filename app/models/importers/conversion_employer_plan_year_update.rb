module Importers
  class ConversionEmployerPlanYearUpdate < ConversionEmployerPlanYear

    def calculated_coverage_start
      return @calculated_coverage_start if @calculated_coverage_start
      if coverage_start.present?
        start_date = Date.strptime(coverage_start, "%m/%d/%Y")
        Date.new(default_plan_year_start.year,start_date.month,start_date.day)
      else
        default_plan_year_start
      end
    end

    def find_and_update_plan_year
      employer = find_employer
      found_carrier = find_carrier

      puts "Processing....#{employer.legal_name}...#{employer.fein}" unless Rails.env.test?

      current_coverage_start = calculated_coverage_start
      
      available_plans = Plan.valid_shop_health_plans("carrier", found_carrier.id, current_coverage_start.year)
      reference_plan = select_reference_plan(available_plans)

      if reference_plan.blank?
        errors.add(:base, 'Unable to find a Reference plan with given Hios ID')
      end

      if single_plan_hios_id.blank? && most_common_hios_id.blank? && reference_plan_hios_id.blank?
        errors.add(:base, 'Reference Plan Hios Id missing')
      end

      if plan_selection == 'single_plan' && single_plan_hios_id.blank?
        errors.add(:base, 'Single Plan Hios Id missing')
      end

      plan_year = employer.plan_years.where(:start_on => current_coverage_start).first
      if plan_year.blank?
        errors.add(:base, 'Plan year not imported')
        return false
      end

      if plan_year && plan_year.benefit_groups.size > 1
        errors.add(:base, 'Employer offering more than 1 benefit package')
        return false
      end

      renewing_plan_year = employer.plan_years.where(:start_on => (current_coverage_start + 1.year)).first
      if renewing_plan_year.blank?
        warnings.add(:base, 'Renewing plan year not present')
      end

      if renewing_plan_year && PlanYear::RENEWING_PUBLISHED_STATE.include?(renewing_plan_year.aasm_state)
        errors.add(:base, "Renewing plan year already published. Reference plan can't be updated")
      end

      return false if errors.present?

      plan_year.update(is_conversion: true) unless plan_year.is_conversion

      if plan_year.benefit_groups[0].reference_plan.hios_id != reference_plan.hios_id
        update_reference_plan(plan_year, reference_plan)
        if renewing_plan_year
          renewal_reference_plan = Plan.find(reference_plan.renewal_plan_id)
          update_reference_plan(renewing_plan_year, renewal_reference_plan)
        end
        return true
      else
        errors.add(:base, "Reference plan is same")
        return false
      end
    end

    def update_reference_plan(plan_year, reference_plan)
      plan_year.benefit_groups.each do |benefit_group|
        benefit_group.reference_plan= reference_plan
        benefit_group.elected_plans= benefit_group.elected_plans_by_option_kind
        benefit_group.save!
      end
    end

    def save 
      return false unless valid?
      find_and_update_plan_year
    end
  end
end
