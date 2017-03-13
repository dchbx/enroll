require File.join(Rails.root, "app", "data_migrations", "update_invalid_benefit_group_assignments_for_employer")
# This rake task is to update the invalid benefit group assignments for the EE's
# format: RAILS_ENV=production bundle exec rake migrations:update_invalid_benefit_group_assignments_for_employer fein=536002558
namespace :migrations do
  desc "updating invalid benefit group assignments for specific employer"
  UpdateInvalidBenefitGroupAssignmentsForEmployer.define_task :update_invalid_benefit_group_assignments_for_employer => :environment
end
