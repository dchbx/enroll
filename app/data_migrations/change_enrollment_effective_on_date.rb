
require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeEnrollmentEffectiveOnDate < MongoidMigrationTask
  def migrate
    enrollment = HbxEnrollment.by_hbx_id(ENV['hbx_id'].to_s)
    new_effective_on = Date.strptime(ENV['new_effective_on'].to_s, "%m/%d/%Y")
    enrollment.first.update_attribute(:effective_on, new_effective_on)
    puts "Changed Enrollment effective on date to #{new_effective_on}" unless Rails.env.test?
  end
end
