require File.join(Rails.root, "app", "data_migrations", "update_user_email")
namespace :migrations do
  desc "updating user email with it's respective oim_id"
  UpdateUserEmail.define_task :update_user_email => :environment
end