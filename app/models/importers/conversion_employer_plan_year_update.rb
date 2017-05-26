module Importers
  class ConversionEmployerPlanYearUpdate < ConversionEmployerPlanYearCommon
    validates_length_of :fein, is: 9

    validate :validate_fein
    validate :validate_new_coverage_policy

    validates_presence_of :plan_selection, :allow_blank => false
    validates_numericality_of :enrolled_employee_count, :allow_blank => false

    def calculated_coverage_start
      return @calculated_coverage_start if @calculated_coverage_start
      if coverage_start.present?
        start_date = Date.strptime(coverage_start, "%m/%d/%Y")
        Date.new(default_plan_year_start.year,start_date.month,start_date.day)
      else
        default_plan_year_start
      end
    end

    def validate_fein
      return true if fein.blank?
      found_employer = find_employer
      if found_employer.nil?
        errors.add(:fein, "does not exist")
      else
        # if found_employer.plan_years.any? && (found_employer.profile_source == "conversion")
        #   errors.add(:fein, "employer already has conversion plan years")
        # end
      end
    end

    def validate_new_coverage_policy
      return true if new_coverage_policy.blank?
      if new_coverage_policy_value.blank?
        warnings.add(:new_coverage_policy, "invalid new hire coverage start policy specified (not one of #{HIRE_COVERAGE_POLICIES.keys.join(",")}), defaulting to first of month following date of hire")
      end
    end

    def find_employer
      org = Organization.where(:fein => fein).first
      return nil unless org
      org.employer_profile
    end

    def select_most_common_plan(available_plans, most_expensive_plan)
        if !most_common_hios_id.blank?
          mc_hios = most_common_hios_id.strip
          found_single_plan = available_plans.detect { |pl| (pl.hios_id == mc_hios) || (pl.hios_id == "#{mc_hios}-01") }
          return found_single_plan if found_single_plan
          warnings.add(:most_common_hios_id, "hios id #{most_common_hios_id.strip} not found for most common plan, defaulting to most expensive plan")
        else
          warnings.add(:most_common_hios_id, "no most common hios id specified, defaulting to most expensive plan")
        end
        most_expensive_plan
    end

    def select_reference_plan(available_plans)
      plans_by_cost = available_plans.sort_by { |plan| plan.premium_tables.first.cost }
      most_expensive_plan = plans_by_cost.last
      if (plan_selection == "single_plan")
        if !single_plan_hios_id.blank?
          sp_hios = single_plan_hios_id.strip
          found_single_plan = available_plans.detect { |pl| (pl.hios_id == sp_hios) || (pl.hios_id == "#{sp_hios}-01") }
          return found_single_plan if found_single_plan
          warnings.add(:single_plan_hios_id, "hios id #{single_plan_hios_id.strip} not found for single plan benefit group defaulting to most common plan")
        else
          warnings.add(:single_plan_hios_id, "no hios id specified for single plan benefit group, defaulting to most common plan")
        end
      end

      select_most_common_plan(available_plans, most_expensive_plan)
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

    def map_employees_to_benefit_groups(employer, plan_year)
      bg = plan_year.benefit_groups.first
      employer.census_employees.non_terminated.each do |ce|
        ce.add_benefit_group_assignment(bg)
        ce.save!
      end
    end

    def propagate_errors(plan_year)
      plan_year.errors.each do |attr, err|
        errors.add("plan_year_" + attr.to_s, err)
      end
      plan_year.benefit_groups.first.errors.each do |attr, err|
        errors.add("plan_year_benefit_group_" + attr.to_s, err)
      end
    end
  end
end
