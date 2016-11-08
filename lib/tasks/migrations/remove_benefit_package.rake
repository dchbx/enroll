require File.join(Rails.root, "app", "data_migrations", "remove_benefit_package")
# This rake task is to change the ER's contributions
# RAILS_ENV=production bundle exec rake migrations:remove_benefit_package fein=264793467 aasm_state=renewing_enrolling id=57fba23413c8d602a1000016
namespace :migrations do
  desc "removing benefit group"
  RemoveBenefitPackage.define_task :remove_benefit_package => :environment
end 
