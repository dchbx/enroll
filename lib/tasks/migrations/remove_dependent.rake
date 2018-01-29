require File.join(Rails.root, "app", "data_migrations", "remove_dependent")
# This rake task is to remove a family member
# RAILS_ENV=production bundle exec rake migrations:remove_dependent family_member_id=12345

namespace :migrations do
  desc "remove dependent"
  RemoveDependent.define_task :remove_dependent => :environment
end