require File.join(Rails.root, "app", "data_migrations", "linking_employee_to_new_employer")
# This rake task is to build new employee role
# RAILS_ENV=production bundle exec rake migrations:linking_employee_to_new_employer old_census_employee_id=5808f24f13c8d609b00000c2 new_census_employee_id=5808f3a113c8d609b00000c8 person_id=5808d14413c8d609b000008b
namespace :migrations do
  desc "build new employee role for a census record"
  LinkingEmployeeToNewEmployer.define_task :linking_employee_to_new_employer => :environment
end 
