require File.join(Rails.root, "app", "data_migrations", "update_ce_employment_terminated_on")
# This rake task is to update the termination date of an census employee
# RAILS_ENV=production bundle exec rake migrations:update_ce_employement_terminated_on ce_id=123123123 new_employment_termination_date=12/01/2016
namespace :migrations do
  desc "update_ce_employement_terminated_on"
  UpdateCeEmploymentTerminatedOn.define_task :update_ce_employment_terminated_on => :environment
end




