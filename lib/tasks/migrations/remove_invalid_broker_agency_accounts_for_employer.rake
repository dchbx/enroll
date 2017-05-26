# Rake tasks used to remove invalid broker agency accounts in employer, i.e broker agency accounts with no brokers and broker agency profile.
# To run rake task: RAILS_ENV=production bundle exec rake migrations:remove_invalid_broker_agency_accounts_for_employer fein=800059771
require File.join(Rails.root, "app", "data_migrations", "remove_invalid_broker_agency_accounts_for_employer")

namespace :migrations do
  desc "Updating the aasm_state of the employer to enrolled"
  RemoveInvalidBrokerAgencyAccountsForEmployer.define_task :remove_invalid_broker_agency_accounts_for_employer => :environment
end

