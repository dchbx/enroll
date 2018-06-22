require File.join(Rails.root, "app", "data_migrations", "update_curam_user_records")
# ******Imp Note: Should be used ONLY when confirmed that an user in IAM is already been removed ******
# RAILS_ENV=production bundle exec rake migrations:update_curam_user_records find_user_by="email" user_email="present_email" new_user_name="required_username" action="update_username"
# RAILS_ENV=production bundle exec rake migrations:update_curam_user_records find_user_by="user_name" new_user_email="example@gmail.com" user_name="valid_username" action="update_email"
namespace :migrations do
  desc "destroying headless user records & updating user name, oim id on user & also updating email on person"
  UpdateCuramUserRecords.define_task :update_curam_user_records => :environment
end 
