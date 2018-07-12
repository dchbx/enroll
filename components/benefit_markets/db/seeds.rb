## Populate namespaced seed content in this file
## To run:
##  1) In spec/dummy/db folder, create seed.rb file with following: BenefitMarkets::Engine.load_seed
##  2) In terminal, chdir to spec/dummy, run rake db:seed

require 'mongoid_rails_migrations'

force_collection_drop = false

puts "\n"*3
puts "Start of Engine BenefitMarkets seed"
puts "*"*80

## Move these constants into <engine_name>/config folder
DB_COLLECTION_NAMES = %w(
    benefit_markets_benefit_markets
    benefit_markets_benefit_market_catalogs
    benefit_markets_pricing_models_pricing_models
    benefit_markets_locations_service_areas
    benefit_markets_locations_rating_areas
    benefit_markets_contribution_models_contribution_models
    benefit_markets_locations_county_zips
    benefit_markets_products_products
    benefit_markets_products_actuarial_factors_actuarial_factors
  )

DB_COLLECTION_PRESERVE_NAMES = []
# DB_COLLECTION_PRESERVE_NAMES = %w(
#     benefit_markets_locations_service_areas
#     benefit_markets_locations_rating_areas
#     benefit_markets_locations_county_zips
#   )

## Add following to rspec/rails_helper.rb
## DatabaseCleaner.strategy = :truncation, {:except => DB_COLLECTION_PRESERVE_NAMES}


puts "Dropping engine-specific collections"
Mongoid.default_client.collections.each do |collection|
  if DB_COLLECTION_NAMES.include?(collection.name)
    if DB_COLLECTION_PRESERVE_NAMES.include?(collection.name) && !force_collection_drop
      puts "  preserving collection: #{collection.name}"
    else
      puts "  dropping collection: #{collection.name}"
      collection.drop
    end
  end
end

puts "*"*80
puts "*"*80

## Use DB_COLLECTION_PRESERVE_NAMES && force_collection_drop setting above to determine which
## seedfiles are run
require File.join(File.dirname(__FILE__),'seedfiles', 'cca_seed')

puts "End of Engine BenefitMarkets seed"
puts "*"*80
