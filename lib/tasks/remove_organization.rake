require File.join(Rails.root, "app", "data_migrations", "remove_organization")

# This rake task is to update the invalid benefit group assignments for the EE's
# format: RAILS_ENV=production bundle exec rake migrations:remove_organization fein=009434962
namespace :migrations do
  desc "Deleting Organization "
  RemoveOrganization.define_task :remove_organization => :environment
end