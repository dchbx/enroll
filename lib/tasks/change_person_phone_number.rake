require File.join(Rails.root, "app", "data_migrations", "change_person_phone_number")
# This rake task is to change the person's phone number
# RAILS_ENV=production bundle exec rake migrations:change_person_phone_number hbx_id=531828 phone_kind="work" full_phone_number="2122023123" country_code=""
namespace :migrations do
  desc "changing person_phone_number"
  ChangePersonPhoneNumber.define_task :change_person_phone_number => :environment
end