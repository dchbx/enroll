# Rake task to add Enrollment to EA
# To run rake task: RAILS_ENV=production bundle exec rake migrations:add_enrollment 

require File.join(Rails.root, "app", "data_migrations", "add_enrollment")
namespace :migrations do
  desc "add_enrollment"
  AddEnrollment.define_task :add_enrollment => :environment
end