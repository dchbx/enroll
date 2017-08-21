require File.join(Rails.root, "lib/mongoid_migration_task")

class TerminateCensusEmployeeWithNoHbxEnrollment < MongoidMigrationTask
  def migrate
    raise "hbx id is not present" if ENV['hbx_id'].blank?
    raise "employment_terminated_on is not present" if ENV['employment_terminated_on'].blank?
    employment_terminated_on = ENV['employment_terminated_on'].to_date
    person = Person.by_hbx_id(ENV['hbx_id']).first
    if person.present?
      active_employee_role = person.active_employee_roles[0]
      if active_employee_role.present?
        census_employee = active_employee_role.census_employee
        if census_employee.present?
          census_employee.terminate_employment(employment_terminated_on)
        end
      end
    else
      puts "cannot find person with hbx_id: #{ENV['hbx_id']}" unless Rails.env.test?
    end
  end
end