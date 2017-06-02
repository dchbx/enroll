require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateOldEnrollmentsToCoverageTerminated < MongoidMigrationTask
  def migrate
    enrollment = HbxEnrollment.by_hbx_id(ENV['hbx_id'].to_s)
    enrollment2 = HbxEnrollment.by_hbx_id(ENV['hbx_id_2'].to_s)
    bad_enrollment = HbxEnrollment.by_hbx_id(ENV['hbx_id_3'].to_s)
    bad_enrollment.first.update(hbx_id:enrollment2.first.hbx_id)
    enrollment2.first.update(plan_id:enrollment.first.plan_id)
    enrollment.first.terminate_coverage!
    enrollment2.first.cancel_coverage!
    puts "Changed Enrollment states" unless Rails.env.test?
  end
end
