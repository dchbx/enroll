require File.join(Rails.root, "app", "data_migrations", "migrate_invoices_to_employer_profile")
# This rake task is to migrate invoice documents under organization to employer_profile
# RAILS_ENV=production bundle exec rake migrations:migrate_invoices_to_employer_profile

namespace :migrations do
  desc "migrate invoices from organization to employer_profile"
  MigrateInvoicesToEmployerProfile.define_task :migrate_invoices_to_employer_profile => :environment
end 
