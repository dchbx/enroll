require File.join(Rails.root, "app", "data_migrations", "update_e_case_id")
# This rake task is to change the conversion ER's active or expired external plan year's status to migration expired state
# RAILS_ENV=production bundle exec rake migrations:update_e_case_id hbx_id="19776773" e_case_id=3197177
namespace :migrations do
  desc "updating the e_case_id of the given user with hbx_id"
  UpdateECaseId.define_task :update_e_case_id => :environment
end
