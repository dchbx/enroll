require File.join(Rails.root, "app", "data_migrations", "change_email_of_user")
# This rake task is to change the fein of an given organization
# RAILS_ENV=production bundle exec rake migrations:change_username  user_oimid="123123123" new_email=email@gmail.com


namespace :migrations do
  desc "change email_of_user"
  ChangeEmailOfUser.define_task :change_email_of_user => :environment
end