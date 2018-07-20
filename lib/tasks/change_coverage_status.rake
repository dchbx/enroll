require File.join(Rails.root, "app", "data_migrations", "change_coverage_status")
# This rake task is to change the coverage status of a consumer role
# RAILS_ENV=production bundle exec rake migrations: change_coverage_status hbx_id = "12341", status="true"

namespace :migrations do
  desc "change coverage status for consumer role"
  ChangeCoverageStatus.define_task :change_coverage_status => :environment
end