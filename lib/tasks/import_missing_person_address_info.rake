require File.join(Rails.root, "app", "data_migrations", "import_missing_person_contact_info")
# This rake task is to change the effective on date
# RAILS_ENV=production bundle exec rake migrations:import_missing_person_contact_info
namespace :migrations do
  desc "import missing address and email info from census_employee to person object"
  ImportMissingPersonContactInfo.define_task :import_missing_person_contact_info => :environment
end
