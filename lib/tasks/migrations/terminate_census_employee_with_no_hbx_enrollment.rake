# The rake task is
# RAILS_ENV=production bundle exec rake migrations:terminate_census_employee_with_no_hbx_enrollment hbx_id="" employment_terminated_on=""
require File.join(Rails.root, "app", "data_migrations", "terminate_census_employee_with_no_hbx_enrollment")
namespace :migrations do
  desc "terminate census employee with no hbx enrollment"
  TerminateCensusEmployeeWithNoHbxEnrollment.define_task :terminate_census_employee_with_no_hbx_enrollment => :environment
end
