require File.join(Rails.root, "app", "data_migrations", "delink_broker_agency")
# This rake task is to delink broker agency assisting a person
# RAILS_ENV=production bundle exec rake migrations:delink_broker_agency person_hbx_id="19901804"
namespace :migrations do
  desc "delink_broker_agency"
  DelinkBrokerAgency.define_task :delink_broker_agency => :environment
end
