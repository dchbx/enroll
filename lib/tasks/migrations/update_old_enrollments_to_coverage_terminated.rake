require File.join(Rails.root, "app", "data_migrations", "update_old_enrollments_to_coverage_terminated")
# This rake task is to change the effective on date
# RAILS_ENV=production bundle exec rake migrations:update_old_enrollments_to_coverage_terminated hbx_id=193989 hbx_id_2=350522 hbx_id_3=219566
namespace :migrations do
  desc "update old enrollments to coverage terminated"
  UpdateOldEnrollmentsToCoverageTerminated.define_task :update_old_enrollments_to_coverage_terminated => :environment
end 