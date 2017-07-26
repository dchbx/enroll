require File.join(Rails.root, "app", "data_migrations", "build_ivl_enrollment")
# This rake task is to build ivl enrollment
# RAILS_ENV=production bundle exec rake migrations:build_ivl_enrollment person_hbx_id="183022" effective_on="01/01/2017" hios_id="78079DC0210004-04" active_year=2017 aptc_in_cents=6300.00
namespace :migrations do
  desc "creating a new ivl enrollment"
  BuildIvlEnrollment.define_task :build_ivl_enrollment => :environment
end 
