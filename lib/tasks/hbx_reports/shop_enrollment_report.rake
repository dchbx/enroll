require 'csv'
require File.join(Rails.root, "app", "reports", "hbx_reports", "shop_enrollment_report")
# The idea behind this report is to get a list of all shop enrollments which are currently in EA.
# This report can be executed in two ways they are
# First way is by passing desired purchase dates. Steps to follow
# 1) You need to pull a list of enrollments from glue with this script on a text file(bundle exec rails r script/queries/print_all_policy_ids.rb > all_glue_policies.txt -e production)
# 2) Place that file into the Enroll Root directory.
# 3) Run the below rake task
# RAILS_ENV=production bundle exec rake hbx_reports:shop_enrollment_report purchase_date_start='06/01/2018' purchase_date_end='06/10/2018'

# Another way is by running daily and it will give enrollment details of past 30 days. Steps to follow
# 1) You need to pull a list of enrollments from glue with this script on a text file(bundle exec rails r script/queries/print_all_policy_ids.rb > all_glue_policies.txt -e production)
# 2) Place that file into the Enroll Root directory.
# 3) Run the below rake task
# RAILS_ENV=production bundle exec rake hbx_reports:shop_enrollment_report

#For any errors please do check this file "log/shop_enrollment_report_error.log"

namespace :hbx_reports do
  desc "SHOP Enrollment Recon Report"
  ShopEnrollmentReport.define_task :shop_enrollment_report => :environment
end