require File.join(Rails.root, "app", "data_migrations", "person_add_user")
# This rake task is to add employee role
# RAILS_ENV=production bundle exec rake migrations:person_add_user email=emiliefokkelman@gmail.com hbx_id=19906687
namespace :migrations do
  desc "adds user id to person"
  PersonAddUser.define_task :person_add_user => :environment
end 
