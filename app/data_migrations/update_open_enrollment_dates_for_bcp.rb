require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateOpenEnrollmentDatesForBcp < MongoidMigrationTask
  def migrate
    begin
      benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
      
      bcp = benefit_sponsorship.benefit_coverage_periods.where(title: ENV['title']).first
      new_oe_start_date = Date.strptime((ENV['new_oe_start_date']).to_s, "%m/%d/%Y")
      new_oe_end_date = Date.strptime((ENV['new_oe_end_date']).to_s, "%m/%d/%Y")
     
      bcp.update_attributes!(open_enrollment_start_on: new_oe_start_date, open_enrollment_end_on: new_oe_end_date)

      puts "Updated Open Enrollment start_on: #{new_oe_start_date}, end_on: #{new_oe_end_date}" unless Rails.env.test?
    rescue Exception => e
      Rails.logger.error { "unable to update open enrollment dates due to #{e}" }
    end
  end
end
