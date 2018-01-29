require File.join(Rails.root, "app", "data_migrations", "trigger_dental_exit_notice")
# RAILS_ENV=production bundle exec rake migrations:trigger_dental_exit_notice
namespace :migrations do
  desc "triggering dental exit notice for missing ER groups"
  TriggerDentalExitNotice.define_task :trigger_dental_exit_notice => :environment
end
