require File.join(Rails.root, "app", "data_migrations", "group_conversion_employers_migration")
# This rake task is to change the conversion ER's active or expired external plan year's status to migration expired state
# RAILS_ENV=production bundle exec rake migrations:group_conversion_employers_migration
namespace :migrations do
  desc "migrating group of employers"
  GroupConversionEmployersMigration.define_task :group_conversion_employers_migration => :environment
end 
