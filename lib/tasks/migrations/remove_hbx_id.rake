require File.join(Rails.root, "app", "data_migrations", "remove_hbx_id")
# This rake task is to remove hbx_id from Enroll app
# RAILS_ENV=production bundle exec rake migrations:remove_hbx_id person_hbx_id

namespace :migrations do
  desc "remove hbx id"
  RemoveHbxId.define_task :remove_hbx_id => :environment
end