require File.join(Rails.root, "app", "data_migrations", "request_haven_timeout_verifications")
# This rake task is to send a response to Haven on Timeout for Verifications
# RAILS_ENV=production bundle exec rake migrations:request_haven_timeout_verifications

namespace :migrations do
  desc "response to Haven for Verifications"
  RequestHavenTimeoutVerifications.define_task :request_haven_timeout_verifications => :environment
end
