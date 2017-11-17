require File.join(Rails.root, "app", "data_migrations", "update_family_relationships")
# This rake task is to swap the index of family members in family
# RAILS_ENV=production bundle exec rake migrations:update_family_relationships hbx_id=76656465

namespace :migrations do
  desc "update_primary_family_member_relationships"
  UpdateFamilyRelationships.define_task :update_family_relationships => :environment
end
