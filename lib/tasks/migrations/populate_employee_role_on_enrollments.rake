require File.join(Rails.root, "app", "data_migrations", "populate_employee_role_on_enrollments")

# This rake task is to fix shop enrollments where employee role id missing
# RAILS_ENV=production bundle exec rake migrations:populate_employee_role_on_enrollments effective_on="08/01/2016"

namespace :migrations do
  desc "populating employee role on enrollments"
  PopulateEmployeeRoleOnEnrollments.define_task :populate_employee_role_on_enrollments => :environment
end
