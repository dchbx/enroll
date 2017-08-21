require File.join(Rails.root, "app", "data_migrations", "update_person_name")
# This rake task is to change person name which in turn changes POC name
# RAILS_ENV=production bundle exec rake migrations:update_person_name  hbx_id=900000000 first_name=nadaal last_name=Michael

namespace :migrations do
  desc "update person name"
  UpdatePersonName.define_task :update_person_name => :environment
end