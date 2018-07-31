require File.join(Rails.root, "app", "data_migrations", "populate_conversion_flag")

namespace :migrations do
  desc "Updating conversion flag on plan year by validating all employers profile source"
  PopulateConversionFlag.define_task :populate_conversion_flag => :environment
end