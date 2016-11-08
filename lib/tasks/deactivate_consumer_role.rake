require File.join(Rails.root, "app", "data_migrations", "deactivate_consumer_role")
# This rake task sets is_active? field for consumer role as false
# RAILS_ENV=production bundle exec rake migrations:deactivate_consumer_role hbx_id=18837682

namespace :migrations do
  desc "setting consumer role's is active field as false"
  DeactivateConsumerRole.define_task :deactivate_consumer_role => :environment
end
