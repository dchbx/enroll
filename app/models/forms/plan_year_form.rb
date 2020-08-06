# frozen_string_literal: true

module Forms
  class PlanYearForm < SimpleDelegator
    def initialize(py)
      super(py)
    end

    def carrier_plans_for(c_profile_id)
      ::Plan.valid_shop_health_plans("carrier", c_profile_id, start_on.year).map{|plan| ["#{::Organization.valid_carrier_names[plan.carrier_profile_id.to_s]} - #{plan.name}", plan.id.to_s]}
    end

    def metal_level_plans_for(metal_level)
      ::Plan.valid_shop_health_plans("metal_level", metal_level, start_on.year).map{|plan| ["#{::Organization.valid_carrier_names[plan.carrier_profile_id.to_s]} - #{plan.name}", plan.id.to_s]}
    end

    def self.model_name
      ::PlanYear.model_name
    end

    def assign_plan_year_attributes(atts = {})
      atts.each_pair do |k, v|
        self.send("#{k}=".to_sym, v)
      end
    end

    def self.build(employer_profile, atts)
      new_py = employer_profile.plan_years.new
      self.new(new_py).tap do |new_proxy|
        new_proxy.assign_plan_year_attributes(atts)
      end
    end

    def self.rebuild(plan_year, atts)
      self.new(plan_year).tap do |proxy|
        proxy.assign_plan_year_attributes(atts)
      end
    end
  end
end
