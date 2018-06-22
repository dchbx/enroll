require File.join(Rails.root, "app", "data_migrations", "invoke_hub_response")
# This rake task is to invoke hub response for a person that has an active enrollment and no hub response
# RAILS_ENV=production bundle exec rake migrations:invoke_hub_response hbx_id=477894
namespace :migrations do
  desc "invoking hub response for the person"
  InvokeHubResponse.define_task :invoke_hub_response => :environment
end