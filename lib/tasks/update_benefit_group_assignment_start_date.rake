require File.join(Rails.root, "app", "data_migrations", "update_benefit_group_assignment_start_date")

# This rake task is to update the invalid benefit group assignments for the EE's
# format: RAILS_ENV=production bundle exec rake migrations:update_benefit_group_assignment_start_date fein=536002558
namespace :migrations do
  desc "updating invalid benefit group assignments for specific employer"
  UpdateBenefitGroupAssignmentStartDate.define_task :update_benefit_group_assignment_start_date => :environment
end
