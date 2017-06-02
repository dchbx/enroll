# This will generate a csv file containing list of Brokers who are not in active status with E.R_Name DBA FEIN Broker_Agency Broker_Name Current_Status
# The task to run is RAILS_ENV=production bundle exec rake reports:brokers_not_active_status_report
require File.join(Rails.root, "app", "reports", "hbx_reports", "brokers_not_active_status_report")
namespace :reports do
  desc "List of brokers who are not in active status"
  BrokersNotActiveStatusReport.define_task :brokers_not_active_status_report => :environment
end
