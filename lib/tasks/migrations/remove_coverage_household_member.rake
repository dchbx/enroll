require File.join(Rails.root, "app", "data_migrations", "remove_coverage_household_member")
# RAILS_ENV=production bundle exec rake migrations:remove_coverage_household_member person_hbx_id=19810927 family_member_id=123123123 coverage_household_member_id=8765467 action=remove_invalid_fm
namespace :migrations do
  desc "removefamily member from coverage household"
  RemoveCoverageHouseholdMember.define_task :remove_coverage_household_member => :environment
end