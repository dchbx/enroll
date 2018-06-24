require File.join(Rails.root, "app", "data_migrations", "remove_family_member_from_coverage_household")
# RAILS_ENV=production bundle exec rake migrations:remove_family_member_from_coverage_household person_hbx_id=19810927 family_member_id=123123123
namespace :migrations do
  desc "remove_family member from coverage household"
  RemoveFamilyMemberFromCoverageHousehold.define_task :remove_family_member_from_coverage_household => :environment
end