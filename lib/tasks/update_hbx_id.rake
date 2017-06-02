require File.join(Rails.root, "app", "data_migrations", "update_hbx_id")

# This rake task is to update hbx id associated to correct person & remove incorrect hbx related to person
# format: RAILS_ENV=production bundle exec rake migrations:update_hbx_id valid_hbxid=888888 invalid_hbxid=9999999
namespace :migrations do
  desc "Update Hbx Id "
  UpdateHbxId.define_task :update_hbx_id => :environment
end