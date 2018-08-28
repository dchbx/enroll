require File.join(Rails.root, "app", "data_migrations", "create_new_initial_plan_year_using_another")
# This rake task is to create a new initial plan year using parameters of an existing plan year
# RAILS_ENV=production bundle exec rake migrations:create_new_initial_plan_year_using_another fein=204895454 old_py_start_on=01012017 new_py_start_on=01022017
# pass below env variables based on changes needed in new plan year
# RAILS_ENV=production bundle exec rake migrations:create_new_initial_plan_year_using_another fein=204895454 old_py_start_on=01012017 new_py_start_on=01022017 open_enrollment_start_on='' open_enrollment_end_on='' effective_on_offset='' plan_option_kind='' dental_plan_option_kind=''
namespace :migrations do
  desc "creating intial plan year from an exisiting plan year"
  CreateNewInitialPlanYearUsingAnother.define_task :create_new_initial_plan_year_using_another => :environment
end
