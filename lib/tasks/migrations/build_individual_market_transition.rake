require File.join(Rails.root, "app", "data_migrations", "build_individual_market_transition")

# RAILS_ENV=production bundle exec rake migrations:build_individual_market_transition action="consumer_role_people"
# RAILS_ENV=production bundle exec rake migrations:build_individual_market_transition action="resident_role_people"

namespace :migrations do
  desc "build individual market transitions for existing people"
  BuildIndividualMarketTransition.define_task :build_individual_market_transition => :environment
end