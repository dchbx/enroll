require File.join(Rails.root, "lib/mongoid_migration_task")

class CreateEmployeeRoleForPerson < MongoidMigrationTask
  def migrate
    census_employee = CensusEmployee.where(_id: ENV['ce_id']).first
    person = Person.where(_id: ENV['person_id']).first
    person.employee_roles.build(employer_profile: census_employee.employer_profile, hired_on: census_employee.hired_on, census_employee_id: census_employee.id)
    person.save
    puts "Employee role has bee create for #{person.id}" unless Rails.env.test?
  end
end
