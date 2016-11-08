require File.join(Rails.root, "app", "data_migrations", "delete_dental_enrollments")
namespace :migrations do

  desc "delete dental enrollment"
  task :delete_dental_enrollment => :environment do |t, args|
    DeleteDentalEnrollment.migrate()
  end
end