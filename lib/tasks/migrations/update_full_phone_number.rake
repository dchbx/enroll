# Rake task to Fix existing records which have phone number data but for which full_phone_number is blank
# To run rake task: rake migrations:update_full_phone_number
require File.join(Rails.root, "app", "data_migrations", "update_full_phone_number")
namespace :migrations do
  desc "update full phone number if nil? in person and organization office locations"
  UpdateFullPhoneNumber.define_task :update_full_phone_number => :environment
end
