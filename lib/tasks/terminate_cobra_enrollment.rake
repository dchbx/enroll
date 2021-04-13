require File.join(Rails.root, "app", "data_migrations", "terminate_cobra_enrollment")
 # This rake task is to migrate cobra employees enrollment aasm_state based on cobra enrollment end date
 # RAILS_ENV=production bundle exec rake migrations:terminate_cobra_enrollment
namespace :migrations do
  desc "change enrollment assm_state for cobra employees"
  TerminateCobraEnrollment.define_task :terminate_cobra_enrollment => :environment
end
