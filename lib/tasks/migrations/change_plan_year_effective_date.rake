require File.join(Rails.root, "app", "data_migrations", "change_plan_year_effective_date")
# This rake task is to change the start on date for the plan year
# RAILS_ENV=production bundle exec rake migrations:change_plan_year_effective_date fein=521862391 aasm_state=draft py_new_start_on="12/01/2016" referenece_plan_hios_id="86052DC0460014-01" ref_plan_active_year=2016
namespace :migrations do
  desc "change plan year effective date"
  ChangePlanYearEffectiveDate.define_task :change_plan_year_effective_date => :environment
end 
