require File.join(Rails.root, "app", "data_migrations", "activate_or_deactivate_employer_link_for_broker")
# This rake task is to enable or disable employer link for a broker
# RAILS_ENV=production bundle exec rake migrations:activate_or_deactivate_employer_link_for_broker activate_fein=332623443 deactivate_fein=222222222

namespace :migrations do
  desc "enabling employer link for a broker"
  ActivateOrDeactivateEmpoyerLinkForBroker.define_task :activate_or_deactivate_employer_link_for_broker => :environment
end
