require File.join(Rails.root, "lib/mongoid_migration_task")

class AddingEmployeeRole < MongoidMigrationTask
  def migrate
    census_employee = CensusEmployee.where(_id: ENV['ce_id']).first
    person = Person.where(_id: ENV['person_id']).first
    role = Factories::EnrollmentFactory.find_or_build_employee_role(person, census_employee.employer_profile, census_employee, census_employee.hired_on)
    Factories::EnrollmentFactory.link_census_employee(census_employee, role, census_employee.employer_profile)
    Factories::EnrollmentFactory.save_all_or_delete_new(role)
    census_employee.update_attributes!(employee_role_id: role.id)
    puts "Employee role linked" unless Rails.env.test?
    census_employee.link_employee_role! if census_employee.may_link_employee_role?
  end
end
