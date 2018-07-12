require File.join(Rails.root, "app", "data_migrations", "remove_suppressed_fallon_plans")
# This rake task removes suppressed fallon plans
# RAILS_ENV=production bundle exec rake migrations:remove_suppressed_fallon_plans
namespace :migrations do
  desc "remove remove_suppressed_fallon_plans"
  RemoveSuppressedFallonPlans.define_task :remove_suppressed_fallon_plans => :environment
end
