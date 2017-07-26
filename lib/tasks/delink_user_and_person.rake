require File.join(Rails.root, "app", "data_migrations", "delink_user_and_person")
# This rake task is to build shop enrollment
# RAILS_ENV=production bundle exec rake migrations:delink_user_and_person person_hbx_id="19901804"
namespace :migrations do
  desc "delink_user_and_person"
  DelinkUserAndPerson.define_task :delink_user_and_person => :environment
end
