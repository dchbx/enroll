ENV["ENROLL_SEEDING"] = "true"

reset_tasks = %w(
  tmp:clear
)

puts "*"*80
puts "Clearing session, cache and socket files from tmp"
system "rake #{reset_tasks.join(" ")}"
puts "*"*80

db_tasks = %w(
  db:mongoid:purge
  db:mongoid:remove_indexes
)
puts "*"*80
puts "Purging Database and Removing Indexes"
system "rake #{db_tasks.join(" ")}"
puts "*"*80

puts "*"*80
puts "Start of seed data"
puts "*"*80

puts "*"*80
puts "Loading carriers, plans, and products_qhp"
plan_tables = %w(
  organizations
  plans
  products_qhps
)
restore_database = Mongoid.default_session.options[:database].to_s
dump_location = File.join(File.dirname(__FILE__), 'seedfiles', 'plan_dumps')
restore_location = File.join(dump_location, restore_database)
plan_files = plan_tables.collect(){|table| File.join(restore_location, "#{table}.bson")}
missing_plan_dumps = plan_files.any? {|file| !File.file?(file)}
use_plan_dumps = ! missing_plan_dumps
generate_plan_dumps = missing_plan_dumps

if use_plan_dumps
  puts "Using plan dump files in #{restore_location}"
  plan_files.each do |file|
    restore_command = "mongorestore --drop --noIndexRestore -d #{restore_database} #{file}"
    system restore_command
  end
  puts "::: complete :::"
end

puts "*"*80
puts "Creating Indexes"
system "rake db:mongoid:create_indexes"
puts "::: complete :::"

if missing_plan_dumps
  puts "Running full seed"

  puts "*"*80
  puts "Creating Indexes"
  system "rake db:mongoid:create_indexes"
  puts "::: complete :::"

  puts "*"*80
  puts "Loading carriers and plans"
  require File.join(File.dirname(__FILE__),'seedfiles', 'carriers_seed')
  system "bundle exec rake seed:plans ENROLL_SEEDING=true"
  puts "::: complete :::"

  puts "*"*80
  puts "Loading SERFF data"
  Products::Qhp.delete_all
  system "bundle exec rake xml:plans"
  puts "::: complete :::"

  puts "*"*80
  puts "Loading SERFF PLAN RATE data"
  system "bundle exec rake xml:rates"
  puts "::: complete :::"
  puts "*"*80

  puts "Processing Plan Mapping ..."
  system "bundle exec rake xml:plan_cross_walk"
  puts "Processing Plan Mapping completed"
  puts "*"*80
  puts "Marking plans as standard ..."
  system "bundle exec rake xml:standard_plans"
  puts "Marking plans as standard completed"

  puts "*"*80
  puts "updating cost share variance deductibles"
  system "bundle exec rake serff:update_cost_share_variances"
  puts "updating cost share variance deductibles complete"
  puts "*"*80

  puts "*"*80
  puts "importing provider_directory_urls and rx_formulary_urls for plans"
  system "bundle exec rake import:provider_and_rx_formulary_url"
  puts "importing provider_directory_urls and rx_formulary_urls for plans complete"
  puts "*"*80

  puts "*"*80
  puts "::: Mapping Plans to SBC pdfs in S3 :::"
  system "bundle exec rake sbc:map"
  puts "::: Mapping Plans to SBC pdfs seed complete :::"

  puts "*"*80
  system "bundle exec rake migrations:cat_age_off_renewal_plan"
  puts "*"*80

  require File.join(File.dirname(__FILE__),'seedfiles', 'shop_2015_sbc_files')
  puts "::: complete :::"
  puts "::: Full Seed Complete :::"
end

puts "*"*80
puts "Creating plan dumps"
if generate_plan_dumps
  dump_command = ["mongodump", "-d", restore_database, "-o", dump_location, "-c"]
  system *dump_command, "organizations", "-q", '{"carrier_profile._id": {$exists: true}}'
  system *dump_command, "plans"
  system *dump_command, "products_qhps"
end
puts "::: complete :::"


puts "*"*80
puts "Loading carriers and QLE kinds."
# require File.join(File.dirname(__FILE__),'seedfiles', 'carriers_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'qualifying_life_event_kinds_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'ivl_life_events_seed')
system "bundle exec rake update_seed:qualifying_life_event"
puts "::: complete :::"

puts "*"*80
puts "Loading sanitized people, families, employers, and census."
load_tasks = %w(
  seed:people
  seed:families
  hbx:employers:add[db/seedfiles/employers.csv,db/seedfiles/blacklist.csv]
  hbx:employers:census:add[db/seedfiles/census.csv]
)
system "bundle exec rake #{load_tasks.join(" ")} ENROLL_SEEDING=true"
puts "::: complete :::"

# require File.join(File.dirname(__FILE__),'seedfiles', 'premiums')

puts "*"*80
puts "Loading counties, admins, people, broker agencies, employers, and employees"
require File.join(File.dirname(__FILE__),'seedfiles', 'us_counties_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'admins_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'people_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'broker_agencies_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'employers_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'employees_seed')
puts "::: complete :::"

puts "*"*80
puts "Loading benefit packages."
require File.join(File.dirname(__FILE__),'seedfiles', 'benefit_packages_ivl_2015_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'benefit_packages_ivl_2016_seed')
require File.join(File.dirname(__FILE__),'seedfiles', 'benefit_packages_ivl_2017_seed')
puts "::: benefit packages seed complete :::"

puts "*"*80
system "bundle exec rake permissions:initial_hbx"
puts "*"*80
puts "End of Seed Data"
