# This rake task is used to deactivate POC from employer account.
# RAILS_ENV=production bundle exec rake migrations:deactivate_employer_staff_role fein=123456789 hbx_id=1234
require File.join(Rails.root, "app", "data_migrations", "deactivate_employer_staff_role")

namespace :migrations do
  desc "change fein of an organization"
  DeactivateEmployerStaffRole.define_task :deactivate_employer_staff_role => :environment
end
