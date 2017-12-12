require File.join(Rails.root, "app", "data_migrations", "add_primary_family_to_person")
# This rake task is to add primary family to the person
# RAILS_ENV=production bundle exec rake migrations:add_primary_family_to_person hbx_id=19810245
namespace :migrations do
  desc "adding primary family for the person"
  AddPrimaryFamilyToPerson.define_task :add_primary_family_to_person => :environment
end