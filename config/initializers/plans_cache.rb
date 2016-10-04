include Acapi::Notifiers
require 'date'
Organization.exists(carrier_profile: true).map do |org|
  Plan.valid_shop_health_plans('carrier', org.carrier_profile.id)
end

#cache next year plans if available
this_year = TimeKeeper.date_of_record.year
[this_year, this_year+1].each do |year|
  Plan::REFERENCE_PLAN_METAL_LEVELS.map do |metal_level|
    Plan.valid_shop_health_plans('metal_level', metal_level, year)
  end
end

include Acapi::Notifiers

