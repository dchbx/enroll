require File.join(Rails.root, "lib/mongoid_migration_task")

class MergeEeAndErAccounts < MongoidMigrationTask
  def migrate
    trigger_single_table_inheritance_auto_load_of_child = VlpDocument
    employee_hbx_id= ENV['employee_hbx_id']
    employer_hbx_id= ENV['employer_hbx_id']
    if Person.where(hbx_id: employee_hbx_id).first.nil?
       puts "No employee found with given hbx_id" unless Rails.env.test?
    elsif Person.where(hbx_id: employer_hbx_id).first.nil?
       puts "No employer found with givin hbx_id" unless Rails.env.test?
    else
       employee=Person.where(hbx_id: employee_hbx_id).first
       employer=Person.where(hbx_id: employer_hbx_id).first
       if employer.employer_staff_roles.nil?
         puts "No employer staff role attached to the employer" unless Rails.env.test?
       else
        unless employer_staff_role_already_exist?(employee, employer)
          employee.employer_staff_roles << employer.employer_staff_roles
          employee.employer_staff_roles.flatten!
        else
          puts "Employer staff role already exist" unless Rails.env.test?
        end
         employee.unset(:user_id) if employee.user_id.present?
         employee.user_id = employer.user_id
         employer.unset(:user_id)
         employee.save!
         employee.user.roles.append("employee")
         employee.user.save!
       end
    end
  end

  def employer_staff_role_already_exist?(employee, employer)
    employee.employer_staff_roles.detect { |esr| esr.aasm_state == "is_active" && employer.employer_staff_roles.map(&:employer_profile_id).include?(esr.employer_profile_id) }.present?
  end
end
