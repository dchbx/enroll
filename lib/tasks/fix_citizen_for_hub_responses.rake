require File.join(Rails.root, "app", "data_migrations", "fix_citizen_for_hub_responses")

namespace :migrations do
  desc "Update citizen status for people whose lawful presence input was changed by hub response"
  UpdateCitizenStatus.define_task :update_citizen_status_for_hub_response => :environment
end