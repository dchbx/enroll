require File.join(Rails.root, "app", "data_migrations", "create_or_change_person_address")
# This rake task is to create or change the persons address
# RAILS_ENV=production bundle exec rake migrations:create_or_change_person_address hbx_id=531828 address_kind="work" address_1="123 Main Street" state_code="MA" zip="07451" city="Gotham City"
namespace :migrations do
  desc "creating new or changing person_phone_number"
  CreateOrChangePersonAddress.define_task :create_or_change_person_address => :environment
end