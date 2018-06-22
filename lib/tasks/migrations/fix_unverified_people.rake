require File.join(Rails.root, "app", "data_migrations", "fix_unverified_people")

# RAILS_ENV=production bundle exec rake migrations:fix_unverified_people
namespace :migrations do
  desc "fix unverified people"
  FixUnverifiedPeople.define_task :fix_unverified_people => :environment
end