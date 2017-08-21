require File.join(Rails.root, "app", "data_migrations", "create_broker_agency_account_for_employer")
# This rake task used to create broker agency accounts for employer.
# To run rake task: RAILS_ENV=production bundle exec rake migrations:create_broker_agency_account_for_employer emp_hbx_id=1234 br_agency_hbx_id=6789 br_npn=4444444422 br_start_on=05/01/2017
namespace :migrations do
  desc "rake task used to create broker agency account for employer."
  CreateBrokerAgencyAccountForEmployer.define_task :create_broker_agency_account_for_employer => :environment
end

