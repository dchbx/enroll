require File.join(Rails.root, "app", "data_migrations", "correct_enrollment_status")

namespace :migrations do
  desc "Correct enrollments for ivl market"
  CorrectEnrollmentStatus.define_task :correct_enrollment_status => :environment
end