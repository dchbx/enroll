# Rake task to change Gender of an Employee
# To run rake task: RAILS_ENV=production bundle exec rake migrations:change_broker_npn person_hbx_id="19748191" new_npn="123123"

require File.join(Rails.root, "app", "data_migrations", "change_broker_npn")
namespace :migrations do
  desc "Changing broker's npn"
  ChangeBrokerNpn.define_task :change_broker_npn => :environment
end
