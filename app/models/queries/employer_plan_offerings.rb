# frozen_string_literal: true

module Queries
  class EmployerPlanOfferings
    include Config::AcaModelConcern
    attr_reader :strategy

    def initialize(emp_profile)
      @strategy = if constrain_service_areas?
                    ::Queries::EmployerPlanOfferingStrategies::ForServiceArea.new(emp_profile)
                  else
                    ::Queries::EmployerPlanOfferingStrategies::AllAvailablePlans.new(emp_profile)
                  end
    end

    delegate :single_carrier_offered_health_plans, :metal_level_offered_health_plans, :single_option_offered_health_plans, :sole_source_offered_health_plans, :single_option_offered_dental_plans, :custom_plan_option_offered_dental_plans, :single_carrier_offered_dental_plans, :dental_reference_plans_by_id, :to => :strategy
  end
end
