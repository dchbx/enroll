require File.join(Rails.root, "app", "data_migrations", "add_and_remove_enrollment_member")
# This rake task is to add or/and remove enrollment members from/to hbx enrollment.
# It works as dialogue in the console and request to provide enrollment you want to fix and person to add/remove
# It does all the things only adding, only removing or both.
# RAILS_ENV=production bundle exec rake migrations:add_and_remove_enrollment_member
namespace :migrations do
  desc "adding or removing enrollment members"
  AddAndRemoveEnrollmentMember.define_task :add_and_remove_enrollment_member => :environment
end
