require File.join(Rails.root, "app", "data_migrations", "change_census_employee_dot")
# This rake task is to change the applied aptc amount for a given hbx_id of an hbx enrollment
# RAILS_ENV=production bundle exec rake migrations:change_census_employee_dot census_employee_id="123123123" new_dot="MM/DD/YYYY"
namespace :migrations do
  desc "change cenesus employee dot"
  ChangeCensusEmployeeDot.define_task :change_census_employee_dot => :environment
end