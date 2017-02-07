# This will generate a csv file containing list of duplicate family members with their Person_HBX_ID, Primary_subscriber_HBX_ID.
# The task to run is RAILS_ENV=production bundle exec rake reports:destroy_duplicates_without_enr
require File.join(Rails.root, "app", "reports", "hbx_reports", "destroy_duplicates_without_enr")
namespace :reports do
  desc "List of duplicate family members"
  DestroyDuplicatesWithoutEnr.define_task :destroy_duplicates_without_enr => :environment
end
