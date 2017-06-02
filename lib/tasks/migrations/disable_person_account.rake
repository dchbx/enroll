# Rake task to disable a person account
# To run rake task: RAILS_ENV=production bundle exec rake migrations:disable_person_account hbx_id="19748191"

require File.join(Rails.root, "app", "data_migrations", "disable_person_account")
namespace :migrations do
  desc "Disable_Person_Account"
  DisablePersonAccount.define_task :disable_person_account => :environment
end
