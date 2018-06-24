# RAILS_ENV=production bundle exec rake reports:report_for_bad_eligibile_families
# Rake to generate a CSV with list of families that have bad eligiblity determination.

require File.join(Rails.root, "app", "reports", "hbx_reports", "report_for_bad_eligibile_families")

namespace :reports do
  desc "List of Families with bad eligibility determination"
  ReportForBadEligibileFamilies.define_task :report_for_bad_eligibile_families => :environment
end
