require File.join(Rails.root, "app", "data_migrations", "remove_dependent")
require File.join(Rails.root, "lib", "remove_family_member")
# This rake task is to remove duplicate family member objects for specific cases.
# RAILS_ENV=production bundle exec rake migrations:remove_dependent family_member_ids=12345,23787

namespace :migrations do
  desc "remove dependent"
  RemoveDependent.define_task :remove_dependent => :environment
end
