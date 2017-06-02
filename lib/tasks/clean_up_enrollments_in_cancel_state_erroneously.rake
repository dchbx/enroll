require File.join(Rails.root, "app", "data_migrations", "clean_up_enrollments_in_cancel_state_erroneously")
# This rake task is to change enrollments that were placed into the Terminated state erroneously
# RAILS_ENV=production bundle exec rake migrations:clean_up_enrollments_in_cancel_state_erroneously
namespace :migrations do
  desc "change enrollments that were placed into the Terminated state erroneously"
  CleanUpEnrollmentsInCancelStateErroneously.define_task :clean_up_enrollments_in_cancel_state_erroneously => :environment
end
