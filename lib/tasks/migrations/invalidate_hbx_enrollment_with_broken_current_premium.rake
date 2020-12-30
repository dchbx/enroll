# RAILS_ENV=production bundle exec rake migrations:invalidate_hbx_enrollment_with_broken_current_premium person_hbx_id="12345"

require File.join(Rails.root, "app", "data_migrations", "invalidate_hbx_enrollment_with_broken_current_premium")

namespace :migrations do
  desc "invalidate enrollments with broken current premium"
  InvalidateHbxEnrollmentWithBrokenCurrentPremium.define_task :invalidate_hbx_enrollment_with_broken_current_premium => :environment
end