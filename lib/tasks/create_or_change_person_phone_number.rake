require File.join(Rails.root, "app", "data_migrations", "create_or_change_person_phone_number")
# This rake task is to create or change the person's phone number
# RAILS_ENV=production bundle exec rake migrations:create_or_change_person_phone_number hbx_id=531828 phone_kind="work" full_phone_number="2122023123" country_code=""
namespace :migrations do
  desc "creating new or changing person_phone_number"
  CreateOrChangePersonPhoneNumber.define_task :create_or_change_person_phone_number => :environment
end