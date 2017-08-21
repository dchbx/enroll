require File.join(Rails.root, "app", "data_migrations", "updating_person_phone_number")
# This rake task is to change the broker phone kind
# RAILS_ENV=production bundle exec rake migrations:updating_person_phone_number hbx_id=28a6a8092b7245118cf0b41bc6ac367b area_code=301 number=3555858  ext='' full_number=301593060
namespace :migrations do
  desc "Changing the broker phone kind"
  UpdatingPersonPhoneNumber.define_task :updating_person_phone_number => :environment
end 