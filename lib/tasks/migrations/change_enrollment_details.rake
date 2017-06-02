require File.join(Rails.root, "app", "data_migrations", "change_enrollment_details")
# This rake task is to change the attributes on enrollment
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_details hbx_id=531828 new_effective_on=12/01/2016 action="change_effective_date"
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_details hbx_id=640826 action="revert_termination"
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_details hbx_id=640826 action="termination" terminated_on=12/02/2016

namespace :migrations do
  desc "changing attributes on enrollment"
  ChangeEnrollmentDetails.define_task :change_enrollment_details => :environment
end 
