require File.join(Rails.root, "app", "data_migrations", "update_invalid_benefit_group_assignment_for_census_employee")
# This rake task is to update  benefit group assignment for census employee
# RAILS_ENV=production bundle exec rake migrations:update_invalid_benefit_group_assignment_for_census_employee employee_role_id=572sssss12345
namespace :migrations do
  desc "remove invalid benefit group assignment under census employee"
  UpdateInvalidBenefitGroupAssignmentForCensusEmployee.define_task :update_invalid_benefit_group_assignment_for_census_employee => :environment
end 
