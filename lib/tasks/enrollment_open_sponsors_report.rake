require File.join(Rails.root, "app",'data_migrations', "enrollment_open_sponsors_report")
# Following rake exports all employers who entered open enrollment with in the requested date range

# This rake will only build the detail and non detailed report of enrollment statuses
# RAILS_ENV=production bundle exec rake migrations:enrollment_open_sponsors_report from_date="10/21/2020" to_date="11/05/2020"

namespace :migrations do
  desc "Enrollment open employers report for given date range"
  EnrollmentOpenSponsorsReport.define_task :enrollment_open_sponsors_report => :environment 
end