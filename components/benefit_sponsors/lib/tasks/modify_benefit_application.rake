# frozen_string_literal: true

require File.join(File.dirname(__FILE__), "..", "..", "app", "data_migrations", "modify_benefit_application")

# This rake task is to modify benefit applications - canceling, terminating, re-instating and updating aasm state.
# RAILS_ENV=production bundle exec rake migrations:modify_benefit_application fein=531828 termination_date="12/01/2016" end_on="12/01/2016" action="terminate" off_cycle_renewal="true" notify_trading_partner="true", termination_kind='voluntary/non-payment', termination_reason = "Company went out of business/bankrupt"
# RAILS_ENV=production bundle exec rake migrations:modify_benefit_application fein=640826 action="cancel" notify_trading_partner="true"
# RAILS_ENV=production bundle exec rake migrations:modify_benefit_application fein=640826 action="reinstate"
# RAILS_ENV=production bundle exec rake migrations:modify_benefit_application fein=640826 action="begin_open_enrollment" effective_date="09/01/2018"
# RAILS_ENV=production bundle exec rake migrations:modify_benefit_application fein=640826 action="force_submit_application" effective_date="09/01/2018"
# RAILS_ENV=production bundle exec rake migrations:modify_benefit_application fein=531828 effective_date="12/01/2016" new_start_date="12/01/2016" new_end_date="12/01/2016" action="update_effective_period_and_approve"

namespace :migrations do
  desc "Modifying benefit applications - Cancel, Terminate, Re-instate, Update Aasm State"
  ModifyBenefitApplication.define_task :modify_benefit_application => :environment
end
