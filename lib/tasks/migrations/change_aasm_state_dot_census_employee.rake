require File.join(Rails.root, "app", "data_migrations", "change_aasm_state_dot_census_employee")
# This rake task is to change the aasm_state and  date of termination on census employee
# RAILS_ENV=production bundle exec rake migrations:change_aasm_state_dot_census_employee census_employee_id="59514964faca144bf3000112"
namespace :migrations do
  desc "change cenesus employee dot"
  ChangeAasmStateDotCensusEmployee.define_task :change_aasm_state_dot_census_employee => :environment
end