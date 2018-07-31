require File.expand_path(File.join(File.dirname(__FILE__), "translations_seed"))
require File.expand_path(File.join(File.dirname(__FILE__), "qles_seed"))

require File.expand_path(File.join(File.dirname(__FILE__), "site_seed"))
Mongoid::Migration.say_with_time("Load MA Site") do
  load_cca_site_seed
end

require File.expand_path(File.join(File.dirname(__FILE__), "issuer_profiles_seed"))
Mongoid::Migration.say_with_time("Load MA Issuer Profiles") do
  load_cca_issuer_profiles_seed
end

require File.expand_path(File.join(File.dirname(__FILE__), "benefit_markets_seed"))
Mongoid::Migration.say_with_time("Load MA Benefit Markets") do
  load_cca_benefit_markets_seed
end

require File.expand_path(File.join(File.dirname(__FILE__), "locations_seed"))
Mongoid::Migration.say_with_time("Load MA County Zips") do
  load_cca_locations_county_zips_seed
end
Mongoid::Migration.say_with_time("Load MA Rating Areas") do
  load_ma_locations_rating_areas_seed
end
Mongoid::Migration.say_with_time("Load MA Service Areas") do
  load_ma_locations_service_areas_seed
end

require File.expand_path(File.join(File.dirname(__FILE__), "factors_seed"))
Mongoid::Migration.say_with_time("Load MA Actuarial Factors") do
  load_cca_factors_seed
end

require File.expand_path(File.join(File.dirname(__FILE__), "products_seed"))
Mongoid::Migration.say_with_time("Load MA Products") do
  load_cca_products_seed
end

require File.expand_path(File.join(File.dirname(__FILE__), "pricing_and_contribution_models_seed"))
Mongoid::Migration.say_with_time("Load MA Pricing Models") do
  load_cca_pricing_models_seed
end
Mongoid::Migration.say_with_time("Load MA Contribution Models") do
  load_cca_contribution_models_seed
end

require File.expand_path(File.join(File.dirname(__FILE__), "benefit_market_catalogs_seed"))
Mongoid::Migration.say_with_time("Load MA Benefit Market Catalogs") do
  load_cca_benefit_market_catalogs_seed
end

require File.expand_path(File.join(File.dirname(__FILE__), "employer_profiles_seed"))
require File.expand_path(File.join(File.dirname(__FILE__), "..", "data_migrations_seed"))