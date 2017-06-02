require File.join(Rails.root, "app", "data_migrations", "remove_resident_role")
# This rake task is to clean-up the data and remove resident roles for people
# who were incorrectly given a resident role. 
# RAILS_ENV=production bundle exec rake migrations:remove_resident_role
namespace :migrations do
  desc "remove incorrectly assigned resident role to person id"
  RemoveResidentRole.define_task :remove_resident_role => :environment
end
