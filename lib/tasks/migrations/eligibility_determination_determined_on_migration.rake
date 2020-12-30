require File.join(Rails.root, "app", "data_migrations", "eligibility_determination_determined_on_migration.rb")
# RAILS_ENV=production bundle exec rake migrations:migrate_deprecated_eligibility_determination_field
namespace :migrations do
  desc "Migrate Deprecated determined_on field"
  EligibilityDeterminationDeterminedOnMigration.define_task :migrate_deprecated_eligibility_determination_field => :environment
end
