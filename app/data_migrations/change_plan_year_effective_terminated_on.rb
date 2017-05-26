require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangePlanYearEffectiveTerminatedon < MongoidMigrationTask
  def migrate
    begin
      enrollment = HbxEnrollment.by_hbx_id(ENV['hbx_id'].to_s)
      new_effective_on = Date.strptime(ENV['new_effective_on'].to_s, "%m/%d/%Y")
      new_terminated_on = Date.strptime(ENV['new_terminated_on'].to_s, "%m/%d/%Y")
      enrollment.first.update_attribute(:effective_on, new_effective_on)
      enrollment.first.update_attribute(:terminated_on, new_terminated_on)
      puts "Changed Enrollment effective on date to #{new_effective_on}" unless Rails.env.test?
      puts "Changed Enrollment terminated on date to #{new_terminated_on}" unless Rails.env.test?
    rescue Exception => e
      puts e.message
    end
  end
end