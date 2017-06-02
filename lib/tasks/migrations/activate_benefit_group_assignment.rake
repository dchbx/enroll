require File.join(Rails.root, "app", "data_migrations", "activate_benefit_group_assignment")
# This rake task is to activate an benefit_group_assignment of census employee
# RAILS_ENV=production bundle exec rake migrations:activate_benefit_group_assignment ce_ssn="123456789" bga_id='580e5f31082e766296006dd2'
namespace :migrations do
  desc "activate_benefit_group_assignment"
  ActivateBenefitGroupAssignment.define_task :activate_benefit_group_assignment => :environment
end
