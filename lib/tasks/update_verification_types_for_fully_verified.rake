require File.join(Rails.root, "app", "data_migrations", "update_verification_types")
# RAILS_ENV=production bundle exec rake migrations:update_verification_types

namespace :migrations do
  desc "Update verification types for fully verified consumers"
  UpdateVerificationTypes.define_task :update_verification_types => :environment
end