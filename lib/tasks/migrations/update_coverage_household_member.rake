require File.join(Rails.root, "app", "data_migrations", "update_coverage_household_member")
# This rake task is to add coverage household member to the primary applicant
# RAILS_ENV=production bundle exec rake migrations:update_coverage_household_member hbx_id=1234 family_member_id=543245
namespace :migrations do
  desc "adding coverage household member"
  UpdateCoverageHouseholdMember.define_task :update_coverage_household_member => :environment
end