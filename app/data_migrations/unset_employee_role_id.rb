
require File.join(Rails.root, "lib/mongoid_migration_task")
class UnsetEmplyeeRoleId < MongoidMigrationTask
  def migrate
    p=Person.where(hbx_id: ENV['hbx_id']).first
    if p.present?
      if p.primary_family.present?
        household=p.primary_family.active_household
        if household.hbx_enrollments.present?
          household.hbx_enrollments.each  do |enrollment|
            if enrollment.kind=='individual'&& !enrollment.employee_role_id.nil?
              enrollment.unset(:employee_role_id)
            end
          end
        end
      end
    else
      raise "some error person with hbx_id:#{ENV['hbx_id']} not found"
    end
  end
end
