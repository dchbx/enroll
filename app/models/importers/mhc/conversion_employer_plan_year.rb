module Importers::Mhc
  class ConversionEmployerPlanYear < Importers::ConversionEmployerPlanYear

    CARRIER_MAPPING = {
      "bmc healthnet plan"=>"BMCHP", 
      "fallon community health plan"=>"FCHP",
      "health new england"=>"HNE",
      "neighborhood health plan" => "NHP",
      "harvard pilgrim health care" => "HPHC",
      "boston medical center health plan" => "BMCHP",
      "blue cross blue shield ma" => "BCBS",
      "tufts health plan premier" => "THPP",
      "tufts health direct" => "THPD"
    }

    validate :validate_plan_selection, :validate_reference_plan

    attr_accessor :employee_only_rt_contribution,
      :employee_only_rt_premium,
      :employee_and_spouse_rt_offered,
      :employee_and_spouse_rt_contribution,
      :employee_and_spouse_rt_premium,
      :employee_and_one_or_more_dependents_rt_offered,
      :employee_and_one_or_more_dependents_rt_contribution,
      :employee_and_one_or_more_dependents_rt_premium,
      :family_rt_offered,
      :family_rt_contribution,
      :family_rt_premium

    def initialize(opts = {})
      super(opts)
    end

    def plan_selection=(val)
      @plan_selection = val.to_s.parameterize('_')
    end

    def validate_reference_plan
      found_carrier = find_carrier
      if found_carrier.blank?
        errors.add(:carrer, "carrier not found")
        return
      end

      available_plans = Plan.valid_shop_health_plans("carrier", found_carrier.id, (calculated_coverage_start).year).compact
      select_reference_plan(available_plans, (calculated_coverage_start).year)
    end

    def validate_plan_selection
      if plan_selection != 'sole_source'
        errors.add(:plan_selection, "invalid plan selection specified (not sole source)")
      end
    end

    def service_area_plan_hios_ids(year)
      employer_profile = find_employer
      carrier = find_carrier
      profile_and_service_area_pairs = CarrierProfile.carrier_profile_service_area_pairs_for(employer_profile, year)
      Plan.valid_shop_health_plans_for_service_area("carrier", carrier.id, calculated_coverage_start.year, profile_and_service_area_pairs.select { |pair| pair.first == carrier.id }).pluck(:hios_id)
    end

    def select_reference_plan(available_plans, start_on_year)
      employer = find_employer
      if plan_selection == 'sole_source'
        if !single_plan_hios_id.blank?
          sp_hios = single_plan_hios_id.strip
          service_area_plan_hios_ids_list = service_area_plan_hios_ids(start_on_year)
          if service_area_plan_hios_ids_list.include?(sp_hios) || service_area_plan_hios_ids_list.include?("#{sp_hios}-01")
            found_sole_source_plan = available_plans.detect { |pl| (pl.hios_id == sp_hios) || (pl.hios_id == "#{sp_hios}-01") }
            return found_sole_source_plan if found_sole_source_plan
            errors.add(:single_plan_hios_id, "hios id #{single_plan_hios_id.strip} not found for single plan benefit group")
          else
            errors.add(:single_plan_hios_id, "hios id #{sp_hios} not offered in employer service areas")
          end
        else
          errors.add(:single_plan_hios_id, "no hios id specified for single plan benefit group")
        end
      end
    end
  end
end