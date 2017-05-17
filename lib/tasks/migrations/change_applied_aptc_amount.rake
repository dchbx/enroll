require File.join(Rails.root, "app", "data_migrations", "change_applied_aptc_amount")
# This rake task is to change the applied aptc amount for a given hbx_id of an hbx enrollment
# RAILS_ENV=production bundle exec rake migrations:change_applied_aptc_amount hbx_id=531828 applied_aptc_amount=293
namespace :migrations do
  desc "changing applied aptc amount for an enrollment"
  ChangeAppliedAptcAmount.define_task :change_applied_aptc_amount => :environment
end
