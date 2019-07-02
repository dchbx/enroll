require File.join(Rails.root, "app", "data_migrations", "update_ce_ssn")

#this rake task is used to update person ssn
#RAILS_ENV=production bundle exec rake migrations:update_ce_ssn ce_id="123212321" encrypted_ssn="Adgfhgjhkhjgfhgjhk="

namespace :migrations do
  desc 'update the ce ssn '
  UpdatingCeSsn.define_task :update_ce_ssn => :environment
end

