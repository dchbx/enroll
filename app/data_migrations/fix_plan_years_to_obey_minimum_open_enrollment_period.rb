# Purpose of this datafix:
# The plan year for some organization is not following the validation rule => Open enrollment period is less than minumum: 5 days
# This caused the organization / employer profile to fail saving.
# One issue where this was identified is Bug #8304 where broker was unable to assign GA because it silently failed to update of the employer_profile.
require File.join(Rails.root, "lib/mongoid_migration_task")

class FixPlanYearsToObeyMinimumOpenEnrollmentPeriod < MongoidMigrationTask
  
  def migrate
     file = File.open("fix_plan_year_output.txt", "w")
     organization = Organization.where(fein: ENV['fein']).first
     if organization.blank?
      file.write("Please run the task with a valid FEIN as a parameter. Organization not found!\n")
      return
     end 

     plan_years = organization.employer_profile.plan_years
     oe_minimum_validation_error_message = "open enrollment period is less than minumum: 5 days"
     py_update_count = 0
     plan_years.each do |py|
        minimum_length = PlanYear::RENEWING.include?(py.aasm_state) ? Settings.aca.shop_market.renewal_application.open_enrollment.minimum_length.days
          : Settings.aca.shop_market.open_enrollment.minimum_length.days

        if py.enrollment_period_errors.include?("open enrollment period is less than minumum: #{minimum_length} days")
          py.open_enrollment_start_on = py.open_enrollment_end_on - 4.days # this will make a total of 5 days [start - end] inclusive
          begin
            py.save!
            py_update_count += 1
            file.write("Plan Year (py_ID: #{py.id}) updated with a new open_enrollment_start_on: #{py.open_enrollment_start_on}\n")
          rescue Exception => e
            file.write("Failed to update the bad plan_year (py_ID: #{py.id}). Error Message: #{e}\n")
          end
        end
     end
     file.write("#{py_update_count} PlanYear(s) Updated (Organization : #{organization.legal_name}, FEIN: #{organization.fein})\n")
     file.close unless file.nil?
  end

end