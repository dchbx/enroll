# Rake task to interchange
# To run rake task: RAILS_ENV=production bundle exec rake migrations:bulk_census_employees_termination

require File.join(Rails.root, "app", "data_migrations", "bulk_census_employees_termination")
namespace :migrations do
  desc "bulk_census_employees_termination"
  BulkCensusEmployeesTermination.define_task bulk_census_employees_termination: :environment
end
