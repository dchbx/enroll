require File.join(Rails.root, "app", "data_migrations", "add_coverage_household_member")
# This rake task is to change the effective on date
# RAILS_ENV=production bundle exec rake migrations:add_coverage_household_member hbx_id=b35ffa27cb6a4ac78b73ed06e7fa1e56 
namespace :migrations do
  desc "adding coverage household member"
  AddCoverageHouseholdMember.define_task :add_coverage_household_member => :environment
end 
