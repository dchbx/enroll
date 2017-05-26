require File.join(Rails.root, "app", "data_migrations", "change_email_address")
# This rake task is to change the fein of an given organization
# RAILS_ENV=production bundle exec rake migrations:change_email_address  person_hbx_id="123123123" old_email="123@gmail.com" new_email="321@gmail.com"

namespace :migrations do
  desc "change email address"
  ChangeEmailAddress.define_task :change_email_address => :environment
end