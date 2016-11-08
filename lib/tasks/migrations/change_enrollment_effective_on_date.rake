require File.join(Rails.root, "app", "data_migrations", "change_enrollment_effective_on_date")
# This rake task is to change the effective on date
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_effective_on_date hbx_id=531828 new_effective_on=12/01/2016
namespace :migrations do
  desc "changing effective on date for enrollment"
  ChangeEnrollmentEffectiveOnDate.define_task :change_enrollment_effective_on_date => :environment
end 
