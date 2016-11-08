require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveInvalidBenefitGroupAssignmentForCensusEmployee < MongoidMigrationTask
  def migrate
    id = ENV["employee_role_id"].to_s
    employee_role = EmployeeRole.find(id)
    employee_role.census_employee.benefit_group_assignments.to_a.each do |bga|
      bga.delete if bga.benefit_group.blank? && bga.hbx_enrollments.blank?
    end
  end
end