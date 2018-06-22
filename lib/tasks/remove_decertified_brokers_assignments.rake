require File.join(Rails.root, "app", "data_migrations", "remove_decertified_brokers_assignments")

# RAILS_ENV=production bundle exec rake migrations:remove_decertified_brokers_assignments

namespace :migrations do
  desc "remove decertified broker assignments"
  RemoveDecertifiedBrokersAssignments.define_task :remove_decertified_brokers_assignments => :environment
end