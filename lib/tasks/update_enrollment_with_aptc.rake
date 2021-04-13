# frozen_string_literal: true

#This rake will generate the new enrollment with aptc and terminates/cancels the existing enrollment
# if need to update aptc on terminated enrollment
# RAILS_ENV=production bundle exec rake migrations:update_enrollment_with_aptc enrollment_hbx_id="1234567" new_effective_date="03/01/2020" applied_aptc_amount="904.50" terminated_on="03/31/2020"
# if need to update aptc on coverage selected enrollment.
# RAILS_ENV=production bundle exec rake migrations:update_enrollment_with_aptc enrollment_hbx_id="1234567" new_effective_date="03/01/2020" applied_aptc_amount="904.50"

require File.join(Rails.root, "app", "data_migrations", "update_enrollment_with_aptc")

namespace :migrations do
  desc " Hbx enrollments with aptc"
  UpdateEnrollmentWithAptc.define_task :update_enrollment_with_aptc => :environment
end