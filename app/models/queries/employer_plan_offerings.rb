module Queries
  class EmployerPlanOfferings
    include Config::AcaModelConcern
    attr_reader :strategy

    def initialize(emp_profile)
      if constrain_service_areas?
        @strategy = ::Queries::EmployerPlanOfferingStrategies::ForServiceArea.new(emp_profile)
      else
        @strategy = ::Queries::EmployerPlanOfferingStrategies::AllAvailablePlans.new(emp_profile)
      end
    end

    delegate :single_carrier_offered_health_plans, :metal_level_offered_health_plans, :single_option_offered_health_plans, :sole_source_offered_health_plans, :to => :strategy

  end
end
