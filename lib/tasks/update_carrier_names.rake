require File.join(Rails.root, "app", "data_migrations", "update_carrier_names")
# This rake task adds a new person under covered in the existing enrollment
# RAILS_ENV=production bundle exec rake migrations:update_carrier_names
namespace :migrations do
  desc "update carrier legal names"
  UpdateCarrierNames.define_task :update_carrier_names => :environment
end