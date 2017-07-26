require File.join(Rails.root, "app", "data_migrations", "resolve_census_employee_validation_failures")
# This rake task is to remove the invalid benefit group assignments for the EE's
# format: RAILS_ENV=production bundle exec rake migrations:resolve_census_employee_validation_failures
namespace :migrations do
  desc "correcting the invalid benefit group assignmentsr"
  ResolveCensusEmployeeValidationFailures.define_task :resolve_census_employee_validation_failures => :environment
end
