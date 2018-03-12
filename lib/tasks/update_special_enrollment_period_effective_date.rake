require File.join(Rails.root, "app", "data_migrations", "update_special_enrollment_period_effective_date")
#RAILS_ENV=production bundle exec rake migrations:remove_coverage_household_member special_enrollment_period_id=19810927 effective_date=02/02/2018
namespace :migrations do
  desc "Update special enrollment period effective date"
  UpdateSpecialEnrollmentPeriodEffectiveDate.define_task :update_special_enrollment_period_effective_date => :environment
end
