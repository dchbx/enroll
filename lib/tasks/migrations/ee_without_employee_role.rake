# Rake task to identify and assign employee_role_id for census_employee records after rehire
# RAILS_ENV=production bundle exec rake migrations:ee_without_employee_role

require File.join(Rails.root, "app", "data_migrations", "ee_without_employee_role")
namespace :migrations do
  desc "Query To Identify EE's without Employee_Role"
  EeWithoutEmployeeRole.define_task :ee_without_employee_role => :environment
end
