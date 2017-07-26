require File.join(Rails.root, "app", "data_migrations", "change_enrollment_termination_date")
# This rake task is to change the termination date
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_termination_date hbx_id=531828 new_termination_date=12/01/2016
namespace :migrations do
  desc "changing termination_date_of_enrollment"
  ChangeEnrollmentTerminationDate.define_task :change_enrollment_termination_date => :environment
end
