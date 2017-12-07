require File.join(Rails.root, "app", "data_migrations", "add_subscriber_to_enrollment")
# This rake task sets a hbx_enrollment_member as the subscriber of an enrollment. This is to fix a data issue that an existing enrollment
# no subscriber and can not be transferred to glue
# RAILS_ENV=production bundle exec rake migrations:add_subscriber_to_enrollment policy_hbx_id=477894 hbx_enrollment_member_id=123123123
namespace :migrations do
  desc "add_subscriber_to_enrollment"
  AddSubscriberToEnrollment.define_task :add_subscriber_to_enrollment => :environment
end