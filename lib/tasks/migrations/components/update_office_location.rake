require File.join(Rails.root, "components", "benefit_sponsors", "app", "data_migrations", "update_office_location")

# This rake task used to update an organization's office location
# RAILS_ENV=production bundle exec rake migrations:update_office_location org_hbx_id='1234567' address_kind='primary' address_1='123 Demo St' city='Baltimore' state_code='MD' zip='12345'

namespace :migrations do
  desc "update an organization's office location"
  UpdateOfficeLocation.define_task :update_office_location => :environment
end
