# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdateFieldsOfEmployeeRole < MongoidMigrationTask
  def migrate
    organization_fein = ENV["organization_fein"]

    employee_role_id = ENV["employee_role_id"]
    census_employee_id = ENV["census_employee_id"]

    action = ENV['action']

    case action
    when "update_benefit_sponsors_employer_profile_id"
      update_benefit_sponsors_employer_profile_id(organization_fein, employee_role_id)
    when "update_census_employee_id"
      update_census_employee_id(organization_fein, employee_role_id)
    when "update_with_given_census_employee_id"
      update_with_given_census_employee_id(census_employee_id, employee_role_id)
    else
      puts "The Action defined is not performed in the rake task" unless Rails.env.test?
    end
  end

  def update_benefit_sponsors_employer_profile_id(organization_fein, employee_role_id)
    employer_profile_id = ::BenefitSponsors::Organizations::Organization.employer_by_fein(organization_fein).first.employer_profile.id.to_s
    employee_role = EmployeeRole.find(employee_role_id)

    if employer_profile_id && employee_role
      employee_role.update_attributes!(benefit_sponsors_employer_profile_id: employer_profile_id)
      puts "Successfully updated employee_role with benefit_sponsors_employer_profile_id: #{employer_profile_id}" unless Rails.env.test?
    else
      puts "Couldnot find employer_profile_id and/or employee_role with the given fein: #{organization_fein}, employer_role_id: #{employee_role_id}" unless Rails.env.test?
    end
  rescue StandardError => e
    puts "error: #{e.backtrace}" unless Rails.env.test?
  end

  def update_census_employee_id(organization_fein, employee_role_id)
    census_employees = ::BenefitSponsors::Organizations::Organization.employer_by_fein(organization_fein).first.benefit_sponsorships.first.census_employees
    employee_role = EmployeeRole.find(employee_role_id)

    census_employees.each do |ce|
      if ce.employee_role_id.to_s == employee_role_id && employee_role.census_employee_id.to_s != ce.id.to_s
        employee_role.update_attributes!(census_employee_id: ce.id)
        puts "Successfully updated employee_role with census_employee_id: #{ce.id}" unless Rails.env.test?
      end
    end
  rescue StandardError => e
    puts "error: #{e.backtrace}" unless Rails.env.test?
  end

  def update_with_given_census_employee_id(census_employee_id, employee_role_id)
    census_employee = CensusEmployee.where(id: census_employee_id)
    employee_role = EmployeeRole.find(employee_role_id)
    if employee_role.present? && census_employee.present?
      employee_role.update_attributes!(census_employee_id: census_employee_id)
      puts "Successfully updated employee_role with census_employee_id: #{census_employee_id}" unless Rails.env.test?
    else
      puts "Please check the EE Role id and Census Employee id"
    end
  rescue StandardError => e
    puts "error: #{e.backtrace}" unless Rails.env.test?
  end
end