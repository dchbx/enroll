require File.join(Rails.root, "app", "data_migrations", "triggering_auto_renewals_for_specific_employer")
# This rake task is to trigger the auto renewal enrollments for the census employees
# RAILS_ENV=production bundle exec rake migrations:triggering_auto_renewals_for_specific_employer fein=262304417
# RAILS_ENV=production bundle exec rake migrations:triggering_auto_renewals_for_specific_employer fein=522193344
namespace :migrations do
  desc "triggering auto renewals for a specific ER"
  TriggeringAutoRenewalsForSpecificEmployer.define_task :triggering_auto_renewals_for_specific_employer => :environment
end
