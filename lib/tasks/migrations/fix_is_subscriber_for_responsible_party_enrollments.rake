require File.join(Rails.root, "app", "data_migrations", "fix_is_subscriber_for_responsible_party_enrollments")

# This rake task will search all responsible party enrollments for records where is_subscriber is not set to true.
# If it finds any, it will set the is_subscriber flag to "true" for the oldest enrollee.
namespace :migrations do
  desc "setting the is_subscriber flag to true for the oldest enrollee on responsible party enrollments that don't have a subscriber defined"
  FixIsSubscriberForResponsiblePartyEnrollments.define_task fix_is_subscriber_for_responsible_party_enrollments: :environment
end
