require File.join(Rails.root, "app", "data_migrations", "change_username")
# This rake task is to change the fein of an given organization
# RAILS_ENV=production bundle exec rake migrations:change_username  old_user_oimid="123123123" new_user_oimid="123123123"


namespace :migrations do
  desc "change username"
  ChangeUsername.define_task :change_username => :environment
end