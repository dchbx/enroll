require File.join(Rails.root, "app", "data_migrations", "relationships_update")
# This rake task is to update the relationships in a family as per new implementation.
# RAILS_ENV=production bundle exec rake migrations:relationships_update
namespace :migrations do
  desc "updating the relationships between the persons of a family"
  RelationshipsUpdate.define_task :relationships_update => :environment
end 
