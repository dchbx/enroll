require File.join(Rails.root, "lib/mongoid_migration_task")

class MergeEeAndErWithBothHaveUserAccount < MongoidMigrationTask
  def migrate
    employee_hbx_id= ENV['employee_hbx_id']
    employer_hbx_id= ENV['employer_hbx_id']
    if Person.where(hbx_id: employee_hbx_id).first.nil?
      puts "No employee found with given hbx_id"
    elsif Person.where(hbx_id: employer_hbx_id).first.nil?
      puts "No employer found with givin hbx_id"
    else
      employee=Person.where(hbx_id: employee_hbx_id).first
      employer=Person.where(hbx_id: employer_hbx_id).first
      if employer.employer_staff_roles.nil?
        puts "No employer staff role attached to the employer"
      else
        employee.employer_staff_roles=employer.employer_staff_roles
        employee.save!
        employee.unset(:user_id)
        employee.user_id = employer.user_id
        employer.unset(:user_id)
        employee.save!
        employee.user.roles.append("employee")
        employee.user.save!
      end
    end
  end
end
