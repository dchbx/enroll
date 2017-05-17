module Importers
  class ConversionEmployerPlanYearCommon
    NewHireCoveragePolicy = Struct.new(:kind, :offset)

    include ActiveModel::Validations
    include ActiveModel::Model

    HIRE_COVERAGE_POLICIES = {
#      "date of hire" => NewHireCoveragePolicy.new("date_of_hire", 0),
#      "date of hire equal to effective date" => NewHireCoveragePolicy.new("date_of_hire", 0),
      "first of the month following 30 days" => NewHireCoveragePolicy.new("first_of_month", 30),
      "first of the month following 60 days" => NewHireCoveragePolicy.new("first_of_month", 60),
      "first of the month following date of hire" => NewHireCoveragePolicy.new("first_of_month", 0),
      "on the first of the month following date of employment" => NewHireCoveragePolicy.new("first_of_month", 0)
    }

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

    def plan_selection=(val)
      @plan_selection = (val.to_s =~ /single plan/i) ? "single_plan" : "single_carrier"
    end
  end
end
