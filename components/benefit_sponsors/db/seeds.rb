## Populate namespaced seed content in this file
## To run:
##  1) In spec/dummy/db folder, create seed.rb file with following: BenefitSponsors::Engine.load_seed
##  2) In terminal, chdir to spec/dummy, run rake db:seed

require 'mongoid_rails_migrations'

force_collection_drop = false

puts "\n"*3
puts "Start of Engine BenefitSponsors seed"
puts "*"*80

## Move these constants into <engine_name>/config folder
DB_COLLECTION_NAMES = %w(
    benefit_sponsors_benefit_sponsorships_benefit_sponsorships
    benefit_sponsors_organizations_organizations
    benefit_sponsors_sites
  )

DB_COLLECTION_PRESERVE_NAMES = []

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

puts "End of Engine BenefitSponsors seed"
puts "*"*80
