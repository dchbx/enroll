module Importers
  class ConversionEmployerPlanYear
    NewHireCoveragePolicy = Struct.new(:kind, :offset)

    include ActiveModel::Validations
    include ActiveModel::Model

    HIRE_COVERAGE_POLICIES = {
#     "date of hire" => NewHireCoveragePolicy.new("date_of_hire", 0),
#     "date of hire equal to effective date" => NewHireCoveragePolicy.new("date_of_hire", 0),
      "first of the month following 30 days" => NewHireCoveragePolicy.new("first_of_month", 30),
      "first of the month following 60 days" => NewHireCoveragePolicy.new("first_of_month", 60),
      "first of the month following date of hire" => NewHireCoveragePolicy.new("first_of_month", 0),
      "on the first of the month following date of employment" => NewHireCoveragePolicy.new("first_of_month", 0),
      "first of the month following or coinciding with date of hire" => NewHireCoveragePolicy.new("first_of_month", 0)
    }

    CARRIER_MAPPING = {
      "aetna" => "AHI",
      "carefirst bluecross blueshield" => "GHMSI",
      "kaiser permanente" => "KFMASI",
      "united healthcare" => "UHIC",
      "united health care" => "UHIC",
      "unitedhealthcare" => "UHIC"
    }
    validates_length_of :fein, is: 9

    validate :validate_fein
    validate :validate_new_coverage_policy
    validate :validate_is_conversion_employer

    validates_presence_of :plan_selection, :allow_blank => false
    validates_numericality_of :enrolled_employee_count, :allow_blank => false

    attr_reader :fein, :plan_selection, :carrier

    attr_accessor :action,
      :enrolled_employee_count,
      :new_coverage_policy,
      :new_coverage_policy_value,
      :default_plan_year_start,
      :most_common_hios_id,
      :single_plan_hios_id,
      :reference_plan_hios_id,
      :coverage_start

    attr_reader :warnings

    include ::Importers::ConversionEmployerCarrierValue

    def initialize(opts = {})
      super(opts)
      @warnings = ActiveModel::Errors.new(self)
    end

    include ValueParsers::OptimisticSsnParser.on(:fein)

    def calculated_coverage_start
      return @calculated_coverage_start if @calculated_coverage_start
      default_plan_year_start
    end

    def new_coverage_policy=(val)
      @new_coverage_policy = val
      if val.blank?
        @new_coverage_policy_value = nil
        return val
      end
      @new_coverage_policy_value = HIRE_COVERAGE_POLICIES[val.strip.downcase]
    end

    def fein=(val)
      @fein = prepend_zeros(val.to_s.gsub('-', '').strip, 9)
    end

    def plan_selection=(val)
      @plan_selection = (val.to_s =~ /single plan/i) ? "single_plan" : "single_carrier"
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

    def plan_years_are_active?(plan_years)
      return false if plan_years.empty?
      plan_years.any? do |py|
        PlanYear::PUBLISHED.include?(py.aasm_state) ||
          PlanYear::RENEWING.include?(py.aasm_state)
      end
    end

    def validate_is_conversion_employer
      found_employer = find_employer
      return true unless found_employer
      return true if action.to_s.downcase == 'update'
      if plan_years_are_active?(found_employer.plan_years) 
        errors.add(:fein, "already has active plan years")
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

    def map_employees_to_benefit_groups(employer, plan_year)
      bg = plan_year.benefit_groups.first
      employer.census_employees.non_terminated.each do |ce|
        next unless ce.valid?
        begin
        ce.add_benefit_group_assignment(bg)
        ce.save!
        rescue Exception => e
          puts "Issue adding benefit group to employee:"
          puts "\n#{employer.fein} - #{employer.legal_name} - #{ce.full_name}\n#{e.inspect}\n- #{e.backtrace.join("\n")}"
        end
      end
    end

    def prepend_zeros(number, n)
      (n - number.to_s.size).times { number.prepend('0') }
      number
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
