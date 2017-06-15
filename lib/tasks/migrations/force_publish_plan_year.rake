# Rake task to force publish plan year
# To run rake task: RAILS_ENV=production bundle exec rake migrations:new_file fein="871927262" py_new_start_on="08/01/2017"

require File.join(Rails.root, "app", "data_migrations", "force_publish_plan_year")
namespace :migrations do
  desc "Force publish plan year"
  ForcePublishPlanYear.define_task :new_file => :environment
end
