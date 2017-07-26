require File.join(Rails.root, "app", "data_migrations", "remove_user_record")

# This rake task is to remove user record associated to person
# THIS RAKE TASK SHOULD ONLY BE USED IN CASE OF SMASH CASES
# format: RAILS_ENV=production bundle exec rake migrations:remove_user_record hbx_id=009434962
namespace :migrations do
  desc "Deleting User Record "
  RemoveUserRecord.define_task :remove_user_record => :environment
end
