require File.join(Rails.root, "app", "data_migrations", "add_role_to_user_account")
# This rake task is to add role to a user account
# RAILS_ENV=production bundle exec rake migrations:add_role_to_user_account  user_id= 123456789 new_role="consumer_role"

namespace :migrations do
  desc "add_role_to_user_account"
  AddRoleToUserAccount.define_task :add_role_to_user_account => :environment
end