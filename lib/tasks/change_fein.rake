require File.join(Rails.root, "app", "data_migrations", "change_fein")
# This rake task is to change the fein of an given organization
# RAILS_ENV=production bundle exec rake migrations:change_fein  old_fein = 123456789 new_fein=987654321

namespace :migrations do
  desc "change fein of an organization"
  ChangeFein.define_task :change_fein => :environment
end