require File.join(Rails.root, "app", "data_migrations", "cancel_dental_offerings_from_plan_year")
# This rake task is to remove the dental offerings from the renwing plan year
# RAILS_ENV=production bundle exec rake migrations:cancel_dental_offerings_from_plan_year fein=455582976 aasm_state=active benefit_group_id=579ec9d7faca14708b001f63
namespace :migrations do
  desc "cancel dental offering from the renewing plan year"
  CancelDentalOfferingsFromPlanYear.define_task :cancel_dental_offerings_from_plan_year => :environment
end 
