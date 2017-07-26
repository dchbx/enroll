require File.join(Rails.root, "app", "data_migrations", "add_existing_family_member_as_dependent_to_enrollment")
# This rake task is to add enrollment_member which has existing family member
# RAILS_ENV=production bundle exec rake migrations:add_existing_family_member_as_dependent_to_enrollment hbx_enrollment_id=123123123 family_member_id=321312321 coverage_begin=2016-01-02

namespace :migrations do
  desc "add_existing_family_member_as_dependent_to_enrollment"
  AddExistingFamilyMemberAsDependentToEnrollment.define_task :add_existing_family_member_as_dependent_to_enrollment => :environment
end