require File.join(Rails.root, "app", "data_migrations", "create_renewal_plan_year_and_enrollment")
# This rake task is used to create renewal plan year and passive renewals based on action.

# RAILS_ENV=production bundle exec rake migrations:create_renewal_plan_year_and_passive_renewals fein=123456789 action="renewal_plan_year"

namespace :migrations do
  desc "create renewal plan year/passive renewals based on action"
  CreateRenewalPlanYearAndEnrollment.define_task :create_renewal_plan_year_and_passive_renewals => :environment
end