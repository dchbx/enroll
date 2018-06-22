require File.join(Rails.root, "app", "data_migrations", "remove_one_ce_from_er")

# Usage: Rake task used to remove census employee records which are erroneously entered on the roster..
# format: RAILS_ENV=production bundle exec rake migrations:remove_one_ce_from_er census_employee_id=123123123123
namespace :migrations do
  desc "remove one ce from er "
  RemoveOneCeFromEr.define_task :remove_one_ce_from_er => :environment
end