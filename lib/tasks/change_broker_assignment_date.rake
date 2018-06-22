require File.join(Rails.root, "app", "data_migrations", "change_broker_assignment_date")
# This rake task is to delink broker agency assisting a person
# RAILS_ENV=production bundle exec rake migrations:change_broker_assignment_date person_hbx_id="19901804" start_on=04/04/2019
namespace :migrations do
  desc "change_broker_assignment_date"
  ChangeBrokerAssignmentDate.define_task :change_broker_assignment_date => :environment
end
