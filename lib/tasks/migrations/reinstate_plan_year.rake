# Rake tasks used to reinstate terminated plan year.
# To run rake task: RAILS_ENV=production bundle exec rake migrations:reinstate_plan_year fein=271441903 plan_year_start_on=05/01/2017 update_renewal_enrollment=true update_current_enrollment=true renewing_force_publish=true
require File.join(Rails.root, "app", "data_migrations", "reinstate_plan_year")

namespace :migrations do
  desc "Updating the aasm_state of the plan year to enrolling"
  ReinstatePlanYear.define_task :reinstate_plan_year => :environment
end