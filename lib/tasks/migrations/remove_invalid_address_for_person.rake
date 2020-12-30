require File.join(Rails.root, "app", "data_migrations", "remove_invalid_address_for_person")
# RAILS_ENV=production bundle exec rake migrations:remove_invalid_address_for_person person_hbx_id=8767567 address_id="8748974587438979348"

namespace :migrations do
  desc "remove invalid address for person"
  RemoveInvalidAddressForPerson.define_task :remove_invalid_address_for_person => :environment
end