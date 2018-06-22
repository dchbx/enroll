require File.join(Rails.root, "app", "data_migrations", "remove_consumer_role")
# This rake task is to clean-up the data and remove consumer role for a person
# who should not have a consumer role but already has a valid resisent role.
# pass the person hbx_id for the actual person for whom to destroy the consumer role
# as the environment variable p_to_fix_id,
# e.g. RAILS_ENV=production bundle exec rake migrations:remove_consumer_role p_to_fix_id=123456

namespace :migrations do
  desc "remove incorrectly assigned consumer role to person via hbx_id"
  RemoveConsumerRole.define_task :remove_consumer_role => :environment
end

