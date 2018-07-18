# Rake task to change Gender of an Employee
# To run rake task: RAILS_ENV=production bundle exec rake migrations:broker_email_invitation npn="123123"

require File.join(Rails.root, "app", "data_migrations", "broker_email_invitation")
namespace :migrations do
  desc "Sending broker Invitation Email"
  BrokerEmailInvitation.define_task :broker_email_invitation => :environment
end
