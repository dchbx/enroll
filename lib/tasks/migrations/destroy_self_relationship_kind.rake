require File.join(Rails.root, "app", "data_migrations", "destroy_self_relationship_kind")
# This rake task is to update the person relationship kind
# RAILS_ENV=production bundle exec rake migrations:destroy_self_relationship_kind hbx_id=19810245
namespace :migrations do
  desc "Changing relationship kind for person record"
  DestroySelfRelationshipKind.define_task :destroy_self_relationship_kind => :environment
end