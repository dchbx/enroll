require File.join(Rails.root, "app", "data_migrations", "fix_special_enrollment_period")
# RAILS_ENV=production bundle exec rake migrations:fix_special_enrollment_period person_hbx_id=19810927

namespace :migrations do
  desc "Fix special enrollments"
  FixSpecialEnrollmentPeriod.define_task :fix_special_enrollment_period => :environment
end