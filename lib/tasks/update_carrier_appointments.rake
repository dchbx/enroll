require File.join(Rails.root, "app", "data_migrations", "update_carrier_appointments")
# This rake task is to add employee role
# RAILS_ENV=production bundle exec rake migrations:update_carrier_appointments 
namespace :migrations do
  desc "link an employee for an employer"
  UpdateCarrierAppointments.define_task :update_carrier_appointments => :environment
end 
