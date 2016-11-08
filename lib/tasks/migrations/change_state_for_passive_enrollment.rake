require File.join(Rails.root, "app", "data_migrations", "change_state_for_passive_enrollment")
# This rake task is to change the canceled passive enrollment to coverage enrolled status when ER offers both health and dental 
# and if the transition happened to canceled for one of these enrollments.
# The rake task is => RAILS_ENV=production bundle exec rake migrations:change_state_for_passive_enrollment

namespace :migrations do
  desc "Changes aasm state for passive renewal"
  ChangeStateForPassiveEnrollment.define_task :change_state_for_passive_enrollment => :environment
end