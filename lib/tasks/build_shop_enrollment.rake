require File.join(Rails.root, "app", "data_migrations", "build_shop_enrollment")
# This rake task is to build shop enrollment
# RAILS_ENV=production bundle exec rake migrations:build_shop_enrollment person_hbx_id="19901804" effective_on="09/01/2016" plan_year_state="active" new_hbx_id="526384" fein=521147118
namespace :migrations do
  desc "creating a new shop enrollment"
  BuildShopEnrollment.define_task :build_shop_enrollment => :environment
end 
