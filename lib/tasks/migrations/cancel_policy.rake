require File.join(Rails.root, "app", "data_migrations", "cancel_policy")
# This rake task is to cancel hbx enrollmet
# RAILS_ENV=production bundle exec rake migrations:remove_policy hbx_id=531828 
namespace :migrations do
  desc "Cancel Hbx enrollment"
  CancelPolicy.define_task :cancel_policy => :environment
end 
