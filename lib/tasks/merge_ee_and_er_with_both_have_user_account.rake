# this rake task is for merge the er account to the ee account
# both ee and er have user account, want to use er's user account
#expected outcome is to access the ee account from user login

require File.join(Rails.root, "app", "data_migrations", "merge_ee_and_er_with_both_have_user_account")

# RAILS_ENV=production bundle exec rake migrations:merge_ee_and_er_with_both_have_user_account  employee_hbx_id="123123", employer_hbx_id="321321321"
namespace :migrations do
  desc "merge_ee_and_er_with_both_have_user_account"
  MergeEeAndErWithBothHaveUserAccount.define_task :merge_ee_and_er_with_both_have_user_account => :environment
end