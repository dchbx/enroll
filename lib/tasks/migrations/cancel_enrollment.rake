require File.join(Rails.root, "app", "data_migrations", "cancel_enrollment")
# This rake task is to change the effective on date
# RAILS_ENV=production bundle exec rake migrations:cancel_enrollment hbx_id=531828
namespace :migrations do
  desc "cancel enrollment"
  CancelEnrollment.define_task :cancel_enrollment => :environment
end
