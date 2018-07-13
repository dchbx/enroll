require File.join(Rails.root, "app", "data_migrations", "cancel_plan_year")

# RAILS_ENV=production bundle exec rake migrations:cancel_plan_year feins='042266782 042919603 593832832 204245950 475178250 202104454 455416547 042839683 042424820 471805382 510486590 454678255 043637716 464474504 042863971 263934159 042857550 043281393 453557994 462608718 043126642 454652531 043304489 421695917 043545180' plan_year_state="active" plan_year_start_on=06/01/2018

namespace :migrations do
  desc "cancel plan year"
  CancelPlanYear.define_task :cancel_plan_year => :environment
end 
