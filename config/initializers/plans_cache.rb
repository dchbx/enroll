include Acapi::Notifiers
require 'date'
Organization.exists(carrier_profile: true).map do |org|
  Plan.valid_shop_health_plans('carrier', org.carrier_profile.id)
end

Plan::REFERENCE_PLAN_METAL_LEVELS.map do |metal_level|
  Plan.valid_shop_health_plans('metal_level', metal_level)
end
include Acapi::Notifiers

#TODOJF What about 2017 coming up like NOW!
$quote_shop_health_plans = Plan.shop_health_by_active_year(2016).all.entries
$quote_shop_dental_plans = Plan.shop_dental_by_active_year(2016).all.entries

$quote_shop_health_selectors = nil
$quote_shop_health_plan_features = nil
$quote_shop_dental_selectors = nil
$quote_shop_dental_plan_features  = nil