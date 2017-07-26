require File.join(Rails.root, "app", "data_migrations", "change_plan_year_effective_terminated_on")
# This rake task is to change the effective on date
# RAILS_ENV=production bundle exec rake migrations:change_plan_year_effective_terminated_on hbx_id=382635 new_effective_on=11/23/2015 new_terminated_on=12/31/2015 
namespace :migrations do
  desc "Changing Effective_on and Terminated_on fates for plan year"
  ChangePlanYearEffectiveTerminatedon.define_task :change_plan_year_effective_terminated_on => :environment
end 