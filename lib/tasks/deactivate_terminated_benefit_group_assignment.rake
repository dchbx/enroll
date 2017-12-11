require File.join(Rails.root, "app", "data_migrations", "deactivate_terminated_benefit_group_assignment")
# This rake task is to deactivate the terminated benefit group assignment
namespace :migrations do
  desc "deactivating terminated benefit group assignment"
  DeactivateTerminatedBenefitGroupAssignment.define_task :deactivate_terminated_benefit_group_assignment => :environment
end
