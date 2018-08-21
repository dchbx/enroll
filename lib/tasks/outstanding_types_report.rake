# Rake task to find outstanding types. Needs to be run with DB snapshot.
# Run Rake Task: RAILS_ENV=production bundle exec rake reports:outstanding_types_report

require File.join(Rails.root, "app", "reports", "outstanding_types_report")
namespace :reports do
  desc "List of outstanding verification types IVL market"
  OutstandingTypesReport.define_task :outstanding_types_report => :environment
end
