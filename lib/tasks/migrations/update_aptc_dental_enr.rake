require File.join(Rails.root, "app", "data_migrations", "update_aptc_dental_enr")
# This rake task is to change the applied aptc value of a given Dental Enrollment for the User with hbx_id
# RAILS_ENV=production bundle exec rake migrations:update_aptc_dental_enr hbx_id="173795" enr_hbx_id="687745"
namespace :migrations do
  desc "updating applied_aptc_amount of the given Dental Plan for the user with hbx_id"
  UpdateAptcDentalEnr.define_task :update_aptc_dental_enr => :environment
end
