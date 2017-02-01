require File.join(Rails.root, "app", "data_migrations", "update_enrollment_review_status")

namespace :migrations do
  desc "Update Hbx enrollments review status attribute"
  UpdateReviewStatus.define_task :update_enrollment_review_status => :environment
end