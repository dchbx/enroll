# Rake task to fix terminate census employees who are in termination pending state after their employment_terminated_on date passsed.
# To run rake task: rake migrations:termiante_census_employee
require File.join(Rails.root, "app", "data_migrations", "terminate_census_employee")
namespace :migrations do
  desc "terminate census employees in employee_termination_pending state to employment_terminated state"
  TerminateCensusEmployee.define_task :termiante_census_employee => :environment
end
