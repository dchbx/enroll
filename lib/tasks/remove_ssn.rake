require File.join(Rails.root, "app", "data_migrations", "remove_ssn")
# This rake task is to remove ssn from person account
# RAILS_ENV=production bundle exec rake migrations:remove_ssn person_hbx_id

namespace :migrations do
  desc "remove ssn"
  RemoveSsn.define_task :remove_ssn => :environment
end