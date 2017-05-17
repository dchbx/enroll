require File.join(Rails.root, "app", "data_migrations", "update_employee_plan_selection")


#RAILS_ENV=production rake migrations:update_employee_plan_selection
namespace :migrations do
  desc 'update employee plan selection'
  UpdateEmployeePlanSelection.define_task :update_employee_plan_selection => :environment
end


