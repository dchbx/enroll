# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class AddingEmployeeRole < MongoidMigrationTask
  def migrate
    action = ENV['action']
    case action
    when 'Add' then add_employee_role
    when 'Link' then link_employee_role
    else
      raise "Invalid action #{action}!"
    end
  rescue StandardError => e
    e.message
  end

  private

  def add_employee_role
    raise 'Please provide census_employee_id.' if ENV['census_employee_id'].nil?
    census_employee = CensusEmployee.where(_id: ENV['census_employee_id']).first
    raise "No Census Employee found by #{ENV['census_employee_id']}" if census_employee.nil?
    raise 'Please provide person_id.' if ENV['person_id'].nil?
    person = Person.where(_id: ENV['person_id']).first
    raise "Person not found by #{ENV['person_id']}" if person.nil?
    role = Factories::EnrollmentFactory.find_or_build_employee_role(person, census_employee.employer_profile, census_employee, census_employee.hired_on)
    Factories::EnrollmentFactory.link_census_employee(census_employee, role, census_employee.employer_profile)
    Factories::EnrollmentFactory.save_all_or_delete_new(role)
    census_employee.update_attributes!(employee_role_id: role.id)
    puts 'Employee role linked' unless Rails.env.test?
    census_employee.link_employee_role! if census_employee.may_link_employee_role?
  end

  def link_employee_role
    raise 'Please provide census_employee_ids.' if ENV['census_employee_ids'].nil?
    ce_ids = ENV['census_employee_ids'].split(",").map(&:strip)
    census_employees = CensusEmployee.where(:id.in => ce_ids)
    raise "No Census Employee found with #{ce_ids.join(', ')}" if census_employees.blank?
    census_employees.each(&:link_employee_role!)
  end
end
