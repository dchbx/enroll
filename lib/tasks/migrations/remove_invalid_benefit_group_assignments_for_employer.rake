require File.join(Rails.root, "app", "data_migrations", "remove_invalid_benefit_group_assignments_for_employer")
# This rake task is to remove the invalid benefit group assignments for the EE's
# format: RAILS_ENV=production bundle exec rake migrations:remove_invalid_benefit_group_assignments_for_employer fein=521247182,66666666
namespace :migrations do
  desc "removing the invalid benefit group assignments for specific employer"
  RemoveInvalidBenefitGroupAssignmentsForEmployer.define_task :remove_invalid_benefit_group_assignments_for_employer => :environment
end
