require File.join(Rails.root, "app", "data_migrations", "change_incorrect_bookmark_url_in_consumer_role")
# This rake task is to correct the incorrect bookmark_url to the correct one
# RAILS_ENV=production bundle exec rake migrations:change_incorrect_bookmark_url_in_consumer_role 

namespace :migrations do
  desc "correcting the consumer role bookmark url"
  ChangeIncorrectBookmarkUrlInConsumerRole.define_task :change_incorrect_bookmark_url_in_consumer_role => :environment
end
