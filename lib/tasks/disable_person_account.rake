require File.join(Rails.root, "app", "data_migrations", "disable_person_account")

# This rake task is to disable person account
# format: RAILS_ENV=production bundle exec rake migrations:disable_person_account hbx_id=009434962
namespace :migrations do
  desc "Disable_person_account"
  DisablePersonAccount.define_task :disable_person_account => :environment
end
