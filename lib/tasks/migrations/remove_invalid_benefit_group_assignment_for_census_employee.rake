require File.join(Rails.root, "app", "data_migrations", "remove_invalid_benefit_group_assignment_for_census_employee")
# This rake task is to remove invalid benefit group assignment under census employee
# RAILS_ENV=production bundle exec rake migrations:remove_invalid_benefit_group_assignment_for_census_employee employee_role_id=5724e267082e7610fb0099e1
namespace :migrations do
  desc "remove invalid benefit group assignment under census employee"
  RemoveInvalidBenefitGroupAssignmentForCensusEmployee.define_task :remove_invalid_benefit_group_assignment_for_census_employee => :environment
end 
