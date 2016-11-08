require File.join(Rails.root, "app", "data_migrations", "change_employer_contributions")
# This rake task is to change the ER's contributions
# RAILS_ENV=production bundle exec rake migrations:change_employer_contributions fein=264793467 aasm_state=renewing_enrolling relationship=spouse premium=75 offered=true
namespace :migrations do
  desc "changing ER contributions"
  ChangeEmployerContributions.define_task :change_employer_contributions => :environment
end 
