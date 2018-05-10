require File.join(Rails.root, "app", "data_migrations", "update_all_plan_options")
# This rake task is to update plan offerings check at employer, broker level plan purchase
# RAILS_ENV=production bundle exec rake migrations:plan_offerings

namespace :migrations do
  desc "It will update Plan attributes at carrier level filter"
  UpdateAllPlanOptions.define_task :plan_offerings => :environment
  puts "successfully updated the plan attributes" unless Rails.env.test?
end