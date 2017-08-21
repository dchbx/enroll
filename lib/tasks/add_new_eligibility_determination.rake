require File.join(Rails.root, "app", "data_migrations", "add_new_eligibility_determination")
# This rake task adds a new person under covered in the existing enrollment
# RAILS_ENV=production bundle exec rake migrations:add_new_eligibility_determination hbx_id=477894 effective_date="08/01/2017" max_aptc=200000 csr_percent_as_integer=73
namespace :migrations do
  desc "add_new_eligibility_determination"
  AddNewEligibilityDetermination.define_task :add_new_eligibility_determination => :environment
end