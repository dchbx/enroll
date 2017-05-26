#this rake task removes the enrollment member from an hbx_enrollment
#RAILS_ENV=production bundle exec rake migrations:remove_member_from_hbx_enrollment enrollment_hbx_id=18837682
# hbx_enrollment_member_id = "123124123123"
require File.join(Rails.root, "app", "data_migrations", "remove_member_from_hbx_enrollment")

namespace :migrations do
  desc "remove_member_from_hbx_enrollment"
  RemoveMemberFromHbxEnrollment.define_task :remove_member_from_hbx_enrollment => :environment
end