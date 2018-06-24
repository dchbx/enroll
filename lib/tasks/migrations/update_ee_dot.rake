# Rake task to update Termination Date of an Employee
# To run rake task: RAILS_ENV=production bundle exec rake migrations:update_ee_dot id="57f6736afaca1458cc000011" employment_terminated_on="12/30/2016" coverage_terminated_on="12/30/2016"

require File.join(Rails.root, "app", "data_migrations", "update_ee_dot")
namespace :migrations do
  desc "Update Termination Date for an Employee"
  UpdateEeDot.define_task :update_ee_dot => :environment
end
