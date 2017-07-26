require File.join(Rails.root, "app", "data_migrations", "move_user_account_between_two_people_accounts")

# This rake task is to move user account from person1 to person2 and disconnect the user from person1
# RAILS_ENV=production bundle exec rake migrations:move_user_account_between_two_people_accounts hbx_id_1=123123123 hbx_id_2=321321321

namespace :migrations do
  desc "move user account between two people accounts"
  MoveUserAccountBetweenTwoPeopleAccounts.define_task :move_user_account_between_two_people_accounts => :environment
end
