require File.join(Rails.root, "app", "data_migrations", "remove_incorrect_person_relationship")
# This rake task is remove person relationship
# get approval from your lead BA before using this rake task.
# RAILS_ENV=production bundle exec rake migrations:remove_incorrect_person_relationship hbx_id="19898136" _id="5963a063f1244e0b7c000056"
namespace :migrations do
  desc "remove person relationship record"
  RemoveIncorrectPersonRelationship.define_task :remove_incorrect_person_relationship => :environment
end 
