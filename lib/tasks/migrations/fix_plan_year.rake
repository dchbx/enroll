require File.join(Rails.root, "app", "data_migrations", "fix_plan_year")
# This rake task to update plan year state and enrollments
# RAILS_ENV=production bundle exec rake migrations:fix_plan_year_state fein=521756243 start_on=11/01/2017 end_on=10/31/2017 terminated_on='' aasm_state='terminated'

namespace :migrations do
  desc "changing attributes on enrollment"
  FixPlanYear.define_task :fix_plan_year_state => :environment
end
