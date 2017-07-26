# Rake task to update Termination Date of an Employee
# To run rake task: RAILS_ENV=production bundle exec rake migrations:remove_termination_date_from_enrollment enrollment_hbx_id=321321321

require File.join(Rails.root, "app", "data_migrations", "remove_termination_date_from_enrollment")
namespace :migrations do
  desc "Remove Termination Date From Enrollment"
  RemoveTerminationDateFromEnrollment.define_task :remove_termination_date_from_enrollment => :environment
end
