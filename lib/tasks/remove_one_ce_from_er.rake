require File.join(Rails.root, "app", "data_migrations", "remove_one_ce_from_er")

# This rake task is to remove one census employee from the employer's roaster
# format: RAILS_ENV=production bundle exec rake migrations:remove_one_ce_from_er fein=009434962 ce_id=123123123123
namespace :migrations do
  desc "remove one ce from er "
  RemoveOneCeFromEr.define_task :remove_one_ce_from_er => :environment
end