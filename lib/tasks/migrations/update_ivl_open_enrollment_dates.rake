require File.join(Rails.root, "app", "data_migrations", "update_ivl_open_enrollment_dates")
# This rake task is to change the open enrollment end on date
# RAILS_ENV=production bundle exec rake migrations:update_ivl_open_enrollment_dates title="Individual Market Benefits 2018" new_oe_start_date="11/01/2017" new_oe_end_date="02/05/2018"
namespace :migrations do
  desc "updating open enrollment dates for benefit coverage period"
  UpdateIVLOpenEnrollmentDates.define_task :update_ivl_open_enrollment_dates => :environment
end
