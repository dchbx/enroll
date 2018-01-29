require File.join(Rails.root, "app", "data_migrations", "assign_attested_residency_state")
# This rake task is to update local residency as attested for every consumer with active enrollment at the moment this task will run
# the task has to be run only once!!! don't run it later because it will update residency status for all active enrollments
# RAILS_ENV=production bundle exec rake migrations:assign_attested_residency_state

namespace :migrations do
  desc "assign_attested_residency_state"
  AssignAttestedResidency.define_task :assign_attested_residency_state => :environment
end