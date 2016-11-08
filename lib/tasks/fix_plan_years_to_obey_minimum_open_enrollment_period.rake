require File.join(Rails.root, "app", "data_migrations", "fix_plan_years_to_obey_minimum_open_enrollment_period")

namespace :migrations do
  desc "fix plan year to have valid open enrollment period of minnimum 5 days."
  FixPlanYearsToObeyMinimumOpenEnrollmentPeriod.define_task :fix_plan_years_to_obey_minimum_open_enrollment_period => :environment
end