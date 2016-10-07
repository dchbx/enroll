require File.join(Rails.root, "app", "data_migrations", "add_hbx_enrollment_member")
# This rake task adds a new person under covered in the existing enrollment
# RAILS_ENV=production bundle exec rake migrations:add_hbx_enrollment_member hbx_id=477894 family_member_id=575ee37750526c5859000084
namespace :migrations do
  desc "adding enrollment member record for an enrollment"
  AddHbxEnrollmentMember.define_task :add_hbx_enrollment_member => :environment
end 