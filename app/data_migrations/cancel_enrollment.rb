
require File.join(Rails.root, "lib/mongoid_migration_task")

class CancelEnrollment < MongoidMigrationTask
  def migrate
    enrollment = HbxEnrollment.by_hbx_id(ENV['hbx_id'].to_s)
    enrollment.first.update_attribute(:aasm_state, "coverage_canceled")
    puts "Changed Enrollment with hbx_id #{enrollment.first.hbx_id} to  coverage_canceled state" unless Rails.env.test?
  end
end
