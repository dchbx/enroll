require File.join(Rails.root, "app", "data_migrations", "enrollment_data_update")

namespace :migrations do
  desc "Correct the enrollment"
  EnrollmentDataUpdate.define_task :enrollment_data_update => :environment
end