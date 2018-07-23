require File.join(Rails.root, "components", "benefit_sponsors", "app", "data_migrations", "modify_benefit_application")

# This rake task is to modify benefit applications - canceling, terminating, re-instating and updating aasm state.
# pass termination_notice="true" in order to send termination notice to both employer and employees
# RAILS_ENV=production bundle exec rake migrations:modify_benefit_application fein=531828 termination_date="12/01/2016" end_on="12/01/2016" action="terminate" termination_notice="true"
# RAILS_ENV=production bundle exec rake migrations:modify_benefit_application fein=640826 action="cancel"
# RAILS_ENV=production bundle exec rake migrations:modify_benefit_application fein=640826 action="reinstate"
# RAILS_ENV=production bundle exec rake migrations:modify_benefit_application fein=640826 action="update_aasm_state" to_state="draft"

namespace :migrations do
  desc "Modifying benefit applications - Cancel, Terminate, Re-instate, Update Aasm State"
  ModifyBenefitApplication.define_task :modify_benefit_application => :environment
end