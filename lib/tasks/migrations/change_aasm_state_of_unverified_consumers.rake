require File.join(Rails.root, "app", "data_migrations", "change_aasm_state_of_unverified_consumers")
# RAILS_ENV=production bundle exec rake migrations:activate_benefit_group_assignment
namespace :migrations do
  desc "change_aasm_state_unverified_consumers"
  ChangeAASMStateOfUnVerifiedConsumers.define_task :change_aasm_state_unverified_consumers => :environment
end