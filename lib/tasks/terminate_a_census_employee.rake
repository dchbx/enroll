require File.join(Rails.root, "app", "data_migrations", "terminate_a_census_employee")
# This rake task is to terminate a census employee from a employer roster
# RAILS_ENV=production bundle exec rake migrations:terminate_a_census_employee  id=56fe3691f1244e24ac001914 termination_date=11/21/2017

namespace :migrations do
  desc "terminate a census_employee"
  TerminateACensusEmployee.define_task :terminate_a_census_employee => :environment
end