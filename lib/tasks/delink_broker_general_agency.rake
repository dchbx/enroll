require File.join(Rails.root, "app", "data_migrations", "delink_broker_general_agency")
# This rake task is to change the fein of an given organization
# RAILS_ENV=production bundle exec rake migrations:delink_broker_general_agency

namespace :migrations do
  desc "deleting old broker creating  broker agency and updating general agency information "
  DelinkBrokerGeneralAgency.define_task :delink_broker_general_agency => :environment
end