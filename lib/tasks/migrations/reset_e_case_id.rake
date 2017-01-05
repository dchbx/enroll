require File.join(Rails.root, "app", "data_migrations", "reset_e_case_id")
# This rake task is to disassociate the e_case_id of the primary_family for a given hbx_id
# RAILS_ENV=production bundle exec rake migrations:reset_e_case_id hbx_id=531828
namespace :migrations do
  desc "disassociating e_case_id for enrollment"
  ResetECaseId.define_task :reset_e_case_id => :environment
end
