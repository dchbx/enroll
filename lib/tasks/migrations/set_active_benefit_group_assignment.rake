require File.join(Rails.root, "app", "data_migrations", "set_active_benefit_group_assignment")
namespace :migrations do
  desc "update full phone number if nil? in person and organization office locations"
  SetActiveBenefitGroupAssignment.define_task :set_active_benefit_group_assignment => :environment
end
