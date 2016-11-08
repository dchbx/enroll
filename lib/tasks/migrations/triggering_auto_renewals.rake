require File.join(Rails.root, "app", "data_migrations", "triggering_auto_renewals")
# This rake task is to trigger the auto renewal enrollments for the census employees by deleting the incorrect ones
# RAILS_ENV=production bundle exec rake migrations:triggering_auto_renewals py_start_on="12/01/2016"
namespace :migrations do
  desc "triggering auto renewals for conversion ER's"
  TriggeringAutoRenewals.define_task :triggering_auto_renewals => :environment
end
