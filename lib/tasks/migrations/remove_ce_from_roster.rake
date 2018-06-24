require File.join(Rails.root, "app", "data_migrations", "remove_ce_from_roster")
# This rake task is to remove census employee from the roaster and disconnect the census employee from the employee role
# RAILS_ENV=production bundle exec rake migrations:remove_ce_from_roster ce_id="123123123123"
namespace :migrations do
  desc "remove_ce_from_roster"
  RemoveCeFromRoster.define_task :remove_ce_from_roster => :environment
end
