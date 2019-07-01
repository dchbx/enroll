require File.join(Rails.root, "app", "data_migrations", "update_aptc")

# RAILS_ENV=production bundle exec rake migrations:update_aptc
namespace :migrations do
  desc "update applied aptc amount by elected amount in hbx_enrollments"
  UpdateAptc.define_task :update_aptc => :environment
end

