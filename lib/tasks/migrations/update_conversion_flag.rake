# Rake task to update Update Conversion Flag
# To run rake task: RAILS_ENV=production bundle exec rake migrations:update_conversion_flag fein="522111704, 300266649, 260077227" profile_source="self_serve"

require File.join(Rails.root, "app", "data_migrations", "update_conversion_flag")
namespace :migrations do
  desc "Update Employer Profile profile source using fein"
  UpdateConversionFlag.define_task :update_conversion_flag => :environment
end