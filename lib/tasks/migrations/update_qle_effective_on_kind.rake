# Rake task to update Update QLE effective on kind
# To run rake task: RAILS_ENV=production bundle exec rake migrations:update_qle_effective_on_kind title="A family member has died"

require File.join(Rails.root, "app", "data_migrations", "update_qle_effective_on_kind")
namespace :migrations do
  desc "Update effective on kind"
  UpdateQleEffectiveOnKind.define_task :update_qle_effective_on_kind => :environment
end