require File.join(Rails.root, "app", "data_migrations", "change_person_dob")
# This rake task is to change the fein of an given organization
# RAILS_ENV=production bundle exec rake migrations:change_person_dob  hbx_id=123123123 new_dob=“02/03/2016"

namespace :migrations do
  desc "change_person_dob"
  ChangePersonDob.define_task :change_person_dob => :environment
end