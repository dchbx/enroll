# Rake task to interchange
# To run rake task: RAILS_ENV=production bundle exec rake migrations:reactivate_tax_household_with_assistance_year primary_person_hbx_id=8ae57f3b5d6245e2998780287d0ade2c applicable_year=2017 max_aptc=1234 csr_percent=52

require File.join(Rails.root, "app", "data_migrations", "reactivate_tax_household_with_assistance_year")
namespace :migrations do
  desc "reactivate_tax_household_with_assistance_year"
  ReactivateTaxHouseholdWithAssistanceYear.define_task :reactivate_tax_household_with_assistance_year => :environment
end
