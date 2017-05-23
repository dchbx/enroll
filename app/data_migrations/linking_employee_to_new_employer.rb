
require File.join(Rails.root, "lib/mongoid_migration_task")

class LinkingEmployeeToNewEmployer < MongoidMigrationTask
  def migrate
    old_census_employee = CensusEmployee.where(_id: ENV['old_census_employee_id']).first
    census_employee = CensusEmployee.where(_id: ENV['new_census_employee_id']).first
    person = Person.where(_id: ENV['person_id']).first
    termination_date = old_census_employee.employment_terminated_on.strftime("%m/%d/%Y")
    if old_census_employee.aasm_state != "employment_terminated" && termination_date <= TimeKeeper.date_of_record.strftime("%m/%d/%Y")
      old_census_employee.update_attribute(:aasm_state, "employment_terminated")
      puts "terminating old census employee" unless Rails.env.test?
    end
    employee_role = Factories::EnrollmentFactory.add_employee_role(user: nil, employer_profile: census_employee.employer_profile, name_pfx: nil, first_name: census_employee.first_name, middle_name: nil, last_name: census_employee.last_name, name_sfx: nil, ssn: census_employee.ssn, dob: census_employee.dob, gender: census_employee.gender, hired_on: census_employee.hired_on)
    census_employee.update_attribute(:employee_role_id, employee_role.first.id)
    puts "Linked with the new employer" unless Rails.env.test?
  end
end
