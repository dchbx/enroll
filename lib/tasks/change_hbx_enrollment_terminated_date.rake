require File.join(Rails.root, "app", "data_migrations", "change_incorrect_termination_date_in_enrollment")
# This rake task is to correct the incorrect termination date of hbx_enrollment
# RAILS_ENV=production bundle exec rake migrations:change_incorrect_termination_date_in_enrollment hbx_id = "12341", termination_date="11/10/2015"

namespace :migrations do
  desc "correcting the termination date of enrollment"
  ChangeIncorrectTerminationDateInEnrollment.define_task :change_incorrect_termination_date_in_enrollment => :environment
end