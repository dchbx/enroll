# Rake tasks used to update the aasm_state of initial plan year to enrolling.
# To run rake task: RAILS_ENV=production bundle exec rake migrations:change_initial_plan_year_aasm_state fein=271441903 plan_year_start_on=05/01/2017
require File.join(Rails.root, "app", "data_migrations", "change_initial_plan_year_aasm_state")

namespace :migrations do
  desc "Updating the aasm_state of the plan year to enrolling"
  ChangeInitialPlanYearAasmState.define_task :change_initial_plan_year_aasm_state => :environment
end