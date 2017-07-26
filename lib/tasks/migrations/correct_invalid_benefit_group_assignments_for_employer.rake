require File.join(Rails.root, "app", "data_migrations", "correct_invalid_benefit_group_assignments_for_employer")
# This rake task is to remove the invalid benefit group assignments from the EE's
# Following rake task can be used to cleanup benefit group assignments for Entire shop market or Single Employer.

# Entire Shop market: 
# RAILS_ENV=production bundle exec rake migrations:correct_invalid_benefit_group_assignments_for_employer

# Single Employer:
# RAILS_ENV=production bundle exec rake migrations:correct_invalid_benefit_group_assignments_for_employer fein=521247182
namespace :migrations do
  desc "correcting the invalid benefit group assignments for specific employer"
  CorrectInvalidBenefitGroupAssignmentsForEmployer.define_task :correct_invalid_benefit_group_assignments_for_employer => :environment
end
