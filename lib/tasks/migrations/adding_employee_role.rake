require File.join(Rails.root, "app", "data_migrations", "adding_employee_role")
# This rake task is to add employee role
# RAILS_ENV=production bundle exec rake migrations:adding_employee_role ce_id=5835bff6082e7645b70000de person_id=53e69677eb899ad9ca02cbfd
namespace :migrations do
  desc "link an employee for an employer"
  AddingEmployeeRole.define_task :adding_employee_role => :environment
end 
