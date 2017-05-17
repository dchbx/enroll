# Rake tasks used to update the aasm_state of the employer to enrolled && plan year aasm state to enrolled.
# To run rake task: RAILS_ENV=production bundle exec rake migrations:employer_status_to_enrolled fein=987654321 plan_year_start_on=02/28/2107
require File.join(Rails.root, "app", "data_migrations", "update_employer_status")

namespace :migrations do
  desc "Updating the aasm_state of the employer to enrolled"
  UpdateEmployerStatus.define_task :employer_status_to_enrolled => :environment
end
