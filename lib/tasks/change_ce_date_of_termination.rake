require File.join(Rails.root, "app", "data_migrations", "change_ce_date_of_termination")
# This rake task is to change the termination date of a census employee
# RAILS_ENV=production bundle exec rake migrations: change_ce_date_of_termination ssn = "12341", date_of_terminate="12/24/2016"

namespace :migrations do
  desc "change ce date of termination"
  ChangeCeDateOfTermination.define_task :change_ce_date_of_termination => :environment
end
