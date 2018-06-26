module Queries
  module EmployerPlanOfferingStrategies
    class ForServiceArea
      attr_reader :employer_profile
      ### THIS MAY NEED UPDATES TO WORK WITH https://devops.dchbx.org/redmine/issues/19024
      def initialize(emp_profile)
        @employer_profile = emp_profile
      end

      def single_carrier_offered_health_plans(carrier_id, start_on)
        profile_and_service_area_pairs = CarrierProfile.carrier_profile_service_area_pairs_for(employer_profile, start_on)
        carrier_profile = CarrierProfile.find(carrier_id)
        query = profile_and_service_area_pairs.select { |pair| pair.first == carrier_profile.id }
        Plan.for_service_areas_and_carriers(query, start_on).shop_market.check_plan_offerings_for_single_carrier.health_coverage.and(hios_id: /-01/)
      end

      def metal_level_offered_health_plans(metal_level, start_on)
        profile_and_service_area_pairs = CarrierProfile.carrier_profile_service_area_pairs_for(employer_profile, start_on)
        Plan.for_service_areas_and_carriers(profile_and_service_area_pairs, start_on).shop_market.check_plan_offerings_for_metal_level.health_coverage.by_metal_level(metal_level).and(hios_id: /-01/)
      end

      def single_option_offered_health_plans(carrier_id, start_on)
        carrier_profile = CarrierProfile.find(carrier_id)
        profile_and_service_area_pairs = CarrierProfile.carrier_profile_service_area_pairs_for(employer_profile, start_on)
        query = profile_and_service_area_pairs.select { |pair| pair.first == carrier_profile.id }
        Plan.for_service_areas_and_carriers(query,  start_on).shop_market.health_coverage.and(hios_id: /-01/)
      end

      def sole_source_offered_health_plans(carrier_id, start_on)
        carrier_profile = CarrierProfile.find(carrier_id)
        profile_and_service_area_pairs = CarrierProfile.carrier_profile_service_area_pairs_for(employer_profile, start_on)
        query = profile_and_service_area_pairs.select { |pair| pair.first == carrier_profile.id }
        Plan.for_service_areas_and_carriers(query,  start_on).shop_market.check_plan_offerings_for_sole_source.health_coverage.and(hios_id: /-01/)
      end
    end
  end
end
