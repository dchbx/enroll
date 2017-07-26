# Rake task to update the legal name of the broker agency legal name
# To run rake task: RAILS_ENV=production bundle exec rake migrations:update_broker_agency_profile_legal_name fein=123123123 new_legal_name="New Name"

require File.join(Rails.root, "app", "data_migrations", "update_broker_agency_profile_legal_name")
namespace :migrations do
  desc "Update_Broker_Agency_Profile_Legal_Name"
  UpdateBrokerAgencyProfileLegalName.define_task :update_broker_agency_profile_legal_name => :environment
end
