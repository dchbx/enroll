require File.join(Rails.root, "app", "data_migrations", "change_enrollment_details")
# This rake task is to change the attributes on enrollment
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_details hbx_id=531828 new_effective_on=12/01/2016 action="change_effective_date"
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_details hbx_id=640826 action="revert_termination"
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_details hbx_id=640826 action="revert_cancel"
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_details hbx_id=640826 action="termination" terminated_on=12/02/2016
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_details hbx_id=640826 action="cancel_enrollment"
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_details hbx_id=609082 action="cancel"
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_details hbx_id=609082 action="generate_hbx_signature"
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_details hbx_id=609082 action="expire_enrollment"
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_details action="transfer_enrollment_from_glue_to_enroll"
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_details hbx_id=609082 new_plan_id="87422093202023" action="change_plan"
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_details hbx_id=609082 new_benefit_group_id="8273298209302" action="change_benefit_group"
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_details hbx_id=397752 action="change_enrollment_status" new_aasm_state=move_to_enrolled
#For mutliple feins
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_details hbx_id=640826,640826,640826 action="revert_termination"

namespace :migrations do
  desc "changing attributes on enrollment"
  ChangeEnrollmentDetails.define_task :change_enrollment_details => :environment
end
