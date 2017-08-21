require File.join(Rails.root, "app", "data_migrations", "change_last_portal_visited")
# This rake task is to change the fein of an given organization
# RAILS_ENV=production bundle exec rake migrations:change_last_portal_visited  user_oimid="123123123" new_url=email@gmail.com


namespace :migrations do
  desc "change email_of_user"
  ChangeLastPortalVisited.define_task :change_last_portal_visited => :environment
end