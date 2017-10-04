require File.join(Rails.root, "app", "data_migrations", "fix_benefit_group_assignments_for_conversion_er_without_active_plan_year")
# past conversion employers where there is no current active plan year & 
# no benefit group assigned to census records.

# RAILS_ENV=production bundle exec rake migrations:fix_benefit_group_assignments_for_conversion_er_without_active_plan_year

# One Time Task
namespace :migrations do
  desc "cancel dental offering from the renewing plan year"
  FixBenefitGroupAssignmentsForConversionErWithoutActivePlanYear.define_task :fix_benefit_group_assignments_for_conversion_er_without_active_plan_year => :environment
end 
