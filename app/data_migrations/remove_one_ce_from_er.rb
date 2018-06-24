require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveOneCeFromEr < MongoidMigrationTask
  def migrate
    begin
      census_employee=CensusEmployee.where(id:ENV['census_employee_id']).first
        if census_employee.nil?
          puts 'Census Employee not found' unless Rails.env.test?
          return
        end
      employee_role = census_employee.employee_role
        if employee_role.present? && employee_role.person.primary_family.active_household.hbx_enrollments.where(employee_role_id: employee_role.id, :"aasm_state".ne => "shopping").present?
            puts "EE enrolled in ER sponsored benefits. Handle them first"  unless Rails.env.test?
             return
        end
        if employee_role.present?
          employee_role.destroy!
          puts "destroyed employee_role record for census employee" unless Rails.env.test?
        end
      census_employee.destroy!
      puts "Deleted the census employee #{census_employee.full_name} from the employer Roster" unless Rails.env.test?
    rescue Exception => e
      puts e.message
    end
  end
end
