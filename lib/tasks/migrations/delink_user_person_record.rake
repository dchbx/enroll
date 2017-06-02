#this rake task is to unset user record from person

require File.join(Rails.root, "app", "data_migrations", "delink_user_person_record")

# RAILS_ENV=production bundle exec rake migrations:delink_user_person_record  hbx_id="19893049"
namespace :migrations do
  desc "delink_user_person_record"
  DelinkUserPersonRecord.define_task :delink_user_person_record => :environment
end