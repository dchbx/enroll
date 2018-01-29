require File.join(Rails.root, "app", "data_migrations", "move_phone_between_person_accounts")
# This rake task is to move hbx_enrollment between two accounts
# RAILS_ENV=production bundle exec rake migrations:move_phone_between_person_accounts from_hbx_id=19778757 to_hbx_id=19778757 phone_id=123123123

namespace :migrations do
  desc "move_phone_between_person_accounts"
  MovePhoneBetweenPersonAccounts.define_task :move_phone_between_person_accounts => :environment
end