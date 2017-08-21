require File.join(Rails.root, "app", "data_migrations", "remove_person_ssn")
# This rake task is to remove ssn from person account
# RAILS_ENV=production bundle exec rake migrations:remove_person_ssn person_hbx_id

namespace :migrations do
  desc "remove person ssn"
  RemovePersonSsn.define_task :remove_person_ssn => :environment
end