require File.join(Rails.root, "app", "data_migrations", "change_person_aasm_terminated_on")
# This rake task is to change the enrollment assm_state and terminated on date
# RAILS_ENV=production bundle exec rake migrations:change_person_aasm_terminated_on  hbx_id=123123123  enrollment_hbx_id=65468783443 terminated_on=“02/03/2016" aasm_state="coverage_terminated"

namespace :migrations do
  desc "change_person_dob"
  ChangePersonAasmTerminatedOn.define_task :change_person_aasm_terminated_on => :environment
end