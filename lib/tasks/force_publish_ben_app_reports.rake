require File.join(Rails.root, "app",'data_migrations', "force_publish_ben_app_reports")
# These rakes manage the force publish process and generate reports

# This rake only builds the detail report of enrollments and their statuses
# RAILS_ENV=production bundle exec rake migrations:force_publish_ben_app_reports start_on_date="12/1/2019" current_date="10/28/2019" detail_report_only="true" 

# This rake only returns the enrollment count
# RAILS_ENV=production bundle exec rake migrations:force_publish_ben_app_reports start_on_date="12/1/2019" current_date="10/28/2019" query_count_only="true" 

# This rake builds the unassigned packages report and attempts to save the EEs
# RAILS_ENV=production bundle exec rake migrations:force_publish_ben_app_reports start_on_date="12/1/2019" current_date="10/28/2019" only_assign_packages="true" 

# This rake will only build the detail and non detailed report of enrollment statuses
# RAILS_ENV=production bundle exec rake migrations:force_publish_ben_app_reports start_on_date="12/1/2019" current_date="10/28/2019" reports_only="true"

# This rake will run the entire force publish process
# RAILS_ENV=production bundle exec rake migrations:force_publish_ben_app_reports start_on_date="12/1/2019"" current_date="10/28/2019" 

namespace :migrations do
  desc "force publish benefit applications and generating reports"
  ForcePublishBenAppReports.define_task :force_publish_ben_app_reports => :environment 
end 
