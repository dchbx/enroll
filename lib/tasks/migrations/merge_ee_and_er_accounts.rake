# this rake task is for merge the er account to the ee account
# er has user, ee has no user
#expected outcome is to access the ee account from user login

require File.join(Rails.root, "app", "data_migrations", "merge_ee_and_er_accounts")

# RAILS_ENV=production bundle exec rake migrations:merge_ee_and_er_accounts  employee_hbx_id="123123", employer_hbx_id="321321321"
namespace :migrations do
  desc "merge_ee_and_er_accounts"
  MergeEeAndErAccounts.define_task :merge_ee_and_er_accounts => :environment
end