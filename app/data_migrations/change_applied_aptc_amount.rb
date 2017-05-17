require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeAppliedAptcAmount < MongoidMigrationTask
  def migrate
    enrollment = HbxEnrollment.by_hbx_id(ENV['hbx_id']).first
    unless HbxEnrollment.by_hbx_id(ENV['hbx_id']).size == 1
      puts "Incorrect number of enrollments returned for hbx_id: #{ENV['hbx_id']}" unless Rails.env.test?
    else
      enrollment.update_attributes(applied_aptc_amount: ENV['applied_aptc_amount'])
      puts "Updated Applied APTC amount for Hbx Enrollment" unless Rails.env.test?
    end
  end
end
