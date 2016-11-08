require File.join(Rails.root, "lib/mongoid_migration_task")

class DeleteDentalEnrollment < MongoidMigrationTask
  def self.migrate(hbx_id_attr)
    p = Person.where(hbx_id: hbx_id_attr).first
    dental_enrollments = p.primary_family.active_household.hbx_enrollments.where(coverage_kind: "dental")
    dental_enrollments.each do |d_enrollment|
      d_enrollment.destroy
    end
  end
end