require File.join(Rails.root, "app", "data_migrations", "update_user_or_person_records")
# This rake task is to update the email and username on User record
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records
#Format:

# To update user oim_id by finding user record from user email
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records find_user_by="email" user_email="example@gmail.com" user_name="valid_oim_id" action="update_username"

# To update user oim_id by finding user record from person hbx_id
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records user_name="valid_oim_id" action="update_username" hbx_id="2394023"

# To update user oim_id by finding user record from user oim_id ["Enter current oim_id next to user_name & new one is next to "new_user_name"]
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records find_user_by="username" user_name="current_oim_id" action="update_username" new_user_name="new_valid_username"

# To update user email by finding user record from user oim_id
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records find_user_by="username" user_email="example@gmail.com" user_name="valid_oim_id" action="update_email"

# To update user email by finding user record from person hbx_id
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records user_email="example@gmail.com" action="update_email" hbx_id="2394023"

# To update user email by finding user record from user email ["Enter current email next to user_email & new one is next to new_user_email"]
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records find_user_by="email" user_email="example@gmail.com" action="update_email" new_user_email="new_valid_email"

# To destroy headless user by email
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records find_user_by="email" user_email="example@gmail.com" headless_user="yes"

# To destroy headless user by oim_id
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records find_user_by="username" user_name="valid_oim_id" headless_user="yes"

# To update home email address on person by finding person through hbx_id
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records action="update_person_home_email" person_email="my_home1198@test.com" hbx_id="2394023"

# To update work email address on person by finding person through hbx_id
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records action="update_person_work_email" person_email="my_home1198@test.com" hbx_id="2394023"

# To create home email address on person & say "yes" (oR) "y" when asked - by finding person through hbx_id
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records action="update_person_home_email" person_email="my_home1198@test.com" hbx_id="2394023"

# To create work email address on person & say "yes" (oR) "y" when asked - by finding person through hbx_id
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records action="update_person_work_email" person_email="my_home1198@test.com" hbx_id="2394023"

# To update home email address on person by finding person through user email & say "yes" oR "y" to create a new one
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records action="update_person_home_email" person_email="my_home1198@test.com" find_user_by="email" user_email="example@gmail.com"

# To update work email address on person by finding person through user email & say "yes" oR "y" to create a new one
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records action="update_person_work_email" person_email="my_home1198@test.com" find_user_by="email" user_email="example@gmail.com"

# To update home email address on person by finding person through user oim_id & say "yes" oR "y" to create a new one
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records action="update_person_home_email" person_email="my_home1198@test.com" find_user_by="username" user_name="valid_oim_id"

# To update work email address on person by finding person through user oim_id & say "yes" oR "y" to create a new one
# RAILS_ENV=production bundle exec rake migrations:update_user_or_person_records action="update_person_work_email" person_email="my_home1198@test.com" find_user_by="username" user_name="valid_oim_id"

namespace :migrations do
  desc "destroying headless user records & updating user name, oim id on user & also updating email on person"
  UpdateUserOrPersonRecords.define_task :update_user_or_person_records => :environment
end 
