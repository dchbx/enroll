require File.join(Rails.root, "app", "data_migrations", "update_user_or_person_records")
# This rake task is to update the email and username on User record
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records
#Format:

# To update oim_id by finding user record from email
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records find_user_by="email" email="example@gmail.com" user_name="valid_oim_id" action="update_username"

# To update email by finding user record from oim_id
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records find_user_by="username" email="example@gmail.com" user_name="valid_oim_id" action="update_email"

# To destroy headless user by email
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records find_user_by="email" email="example@gmail.com" headless_user="yes"

# To destroy headless user by oim_id
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records find_user_by="username" user_name="valid_oim_id" headless_user="yes"

# To update home email address on person
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records action="update_person_home_email" person_email="my_home1198@test.com" hbx_id="2394023"

# To update work email address on person
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records action="update_person_work_email" person_email="my_home1198@test.com" hbx_id="2394023"


namespace :migrations do
  desc "destroying headless user records & updating user name, oim id on user & also updating email on person"
  UpdateUserOrPersonRecords.define_task :update_user_or_person_records => :environment
end 
