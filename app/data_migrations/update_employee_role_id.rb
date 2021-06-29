# frozen_string_literal: true

require File.join(Rails.root,"lib/mongoid_migration_task")
class UpdateEmployeeRoleId < MongoidMigrationTask
  def migrate
    person = get_person
    action = ENV['action'].to_s
    case action
    when "update_employee_role_id_to_enrollment"
      update_employee_role_id_to_enrollment(person) if person.present?
    when "update_employee_role_id_to_ce"
      update_employee_role_id_to_ce(person) if person.present?
    else
      puts "The Action defined is not performed in the rake task" unless Rails.env.test?
    end
  end
end

def get_person
  person_count = Person.where(hbx_id: ENV['hbx_id']).count
  if person_count == 1
    Person.where(hbx_id: ENV['hbx_id']).first
  else
    raise "No Person found (or) found more than 1 Person record" unless Rails.env.test?

  end
end

def update_employee_role_id_to_enrollment(person)
  if person.present? && person.has_active_employee_role? && person.active_employee_roles.count == 1
    active_employee_role_id = person.active_employee_roles.first.id
    person.primary_family.active_household.hbx_enrollments.each do |enr|
      if enr.employee_role_id == active_employee_role_id
        puts "Enrollment #{enr.hbx_id} is pointing towards the right Employee"  unless Rails.env.test?
      else
        enr.update_attributes!(employee_role_id: active_employee_role_id)
        puts "Fixed Enrollment #{enr.hbx_id} by pointing the Enrollment towards the right Employee of hbx id #{person.hbx_id}"  unless Rails.env.test?
      end
    end
  else
    puts "Please check the hbx id the id given is not present or has no active employee roles"  unless Rails.env.test?
  end
end

def update_employee_role_id_to_ce(person)
  if person.present? && person.has_active_employee_role? && person.active_employee_roles.count == 1
    active_employee_role_id = person.active_employee_roles.first.id
    census_employee = person.active_employee_roles.first.census_employee
    if census_employee.employee_role_id == active_employee_role_id
      puts "Census Employee is pointing towards the right Employee Role id"  unless Rails.env.test?
    else
      census_employee.update_attributes!(employee_role_id: active_employee_role_id)
      puts "Fixed Census Employee by pointing the Enrollment towards the right Employee Role id for hbx id #{person.hbx_id}"  unless Rails.env.test?
    end
  else
    puts "Please check the hbx id the id given is not present or has no active employee roles"  unless Rails.env.test?
  end
end
