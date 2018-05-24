require File.join(Rails.root, "app", "data_migrations", "create_employee_role_for_person")
# This rake task is to create employee role
# RAILS_ENV=production bundle exec rake migrations:create_employee_role_for_person census_employee_id=3237892839283 person_id=76238298392323
namespace :migrations do
  desc "Creat employee role for a person"
  CreateEmployeeRoleForPerson.define_task :create_employee_role_for_person => :environment
end
