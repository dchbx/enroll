require File.join(Rails.root, "app", "data_migrations", "extending_open_enrollment_end_date_for_employers")
# This rake task is to change the open enrollment end on date
# RAILS_ENV=production bundle exec rake migrations:extending_open_enrollment_end_date_for_employers py_start_on="12/01/2016" new_oe_end_date="11/15/2016"
namespace :migrations do
  desc "extending the open enrollment end date for conversion employers"
  ExtendingOpenEnrollmentEndDateForEmployers.define_task :extending_open_enrollment_end_date_for_employers => :environment
end
