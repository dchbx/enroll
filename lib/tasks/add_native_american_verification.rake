require File.join(Rails.root, "app", "data_migrations", "add_native_american_verification")

namespace :migrations do
  desc "Add new verification type for Native American"
  AddNativeVerification.define_task :add_native_american_verification => :environment
end