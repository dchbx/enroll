module Queries
  module EmployerPlanOfferingStrategies
    class AllAvailablePlans
      attr_reader :employer_profile

      def initialize(emp_profile)
        @employer_profile = emp_profile
      end

      def single_carrier_offered_health_plans(carrier_id, start_on)
        carrier_profile = CarrierProfile.find(carrier_id)
        Plan.by_active_year(start_on).shop_market.check_plan_offerings_for_single_carrier.health_coverage.by_carrier_profile(carrier_profile).and(hios_id: /-01/)
      end

      def metal_level_offered_health_plans(metal_level, start_on)
        Plan.by_active_year(start_on).shop_market.check_plan_offerings_for_metal_level.health_coverage.by_metal_level(metal_level).and(hios_id: /-01/)
      end

      def single_option_offered_health_plans(carrier_id, start_on)
        carrier_profile = CarrierProfile.find(carrier_id)
        Plan.by_active_year(start_on).shop_market.health_coverage.by_carrier_profile(carrier_profile).and(hios_id: /-01/)
      end

      def sole_source_offered_health_plans(carrier_id, start_on)
        carrier_profile = CarrierProfile.find(carrier_id)
        Plan.by_active_year(start_on).shop_market.check_plan_offerings_for_sole_source.health_coverage.by_carrier_profile(carrier_profile).and(hios_id: /-01/)
      end
    end
  end
end
