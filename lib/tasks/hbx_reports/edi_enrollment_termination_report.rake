# Daily Report: Rake task to find terminated hbx_enrollment
# To Run Rake Task without custom dates: RAILS_ENV=production rake reports:enrollment_termination_on
# To Run Rake Task with custom dates: RAILS_ENV=production rake reports:enrollment_termination_on start_date=Y-m-d end_date=Y-m-d]
# example for running Rake Task with custom dates: bundle exec rake reports:enrollment_termination_on start_date=2016-6-29 end_date=2016-8-30

require File.join(Rails.root, "app", "reports", "hbx_reports", "edi_enrollment_termination_report")
namespace :reports do
  desc "List of people with terminated hbx_enrollment"
  TerminatedHbxEnrollments.define_task :enrollment_termination_on => :environment
end
