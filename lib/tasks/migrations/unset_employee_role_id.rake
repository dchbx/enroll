require File.join(Rails.root, "app", "data_migrations", "unset_employee_role_id")
# This rake task is to delete employee_role_id of enrollments with individual kind
# RAILS_ENV=production bundle exec rake migrations:unset_employee_role_id hbx_id="1234567"
namespace :migrations do
  desc "delete employee_role_id of enrollments with individual kind"
  UnsetEmplyeeRoleId.define_task :unset_employee_role_id => :environment
end