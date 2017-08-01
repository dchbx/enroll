require File.join(Rails.root, "app", "data_migrations", "add_family_members_to_immediate_coverage_household_members")
# RAILS_ENV=production bundle exec rake migrations:add_family_members_to_immediate_coverage_household_members hbx_id=19940787
namespace :migrations do
  desc "add family members to immediate coverage household members"
  AddFamilyMembersToImmediateCoverageHouseholdMembers.define_task :add_family_members_to_immediate_coverage_household_members => :environment
end
