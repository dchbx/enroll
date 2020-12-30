# frozen_string_literal: true

require File.join(Rails.root, 'app', 'data_migrations', 'ivl_enrollment_eligibility_report')
# This rake is to generate monthly IVL Enrollment Eligibility Report.
# RAILS_ENV=production bundle exec rake migrations:ivl_enrollment_eligibility_report

namespace :migrations do
  desc 'generates monthly IVL Eligibility Report'
  IvlEnrollmentEligibilityReport.define_task :ivl_enrollment_eligibility_report => :environment
end
