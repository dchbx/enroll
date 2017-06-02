require File.join(Rails.root, "lib/mongoid_migration_task")
require 'date'
class ChangeCeDateOfTermination < MongoidMigrationTask
  def migrate
    begin
      census_employee=CensusEmployee.by_ssn(ENV['ssn']).first
      new_termination_date = Date.strptime(ENV['date_of_terminate'],'%m/%d/%Y').to_date
      if census_employee.nil?
        puts "No census employee with given ssn was found" unless Rails.env.test?
      elsif census_employee.aasm_state != "employment_terminated"
        puts "The census employee is not in employment terminated state" unless Rails.env.test?
      else
        census_employee.update_attributes(employment_terminated_on: new_termination_date)
        puts "Changed census employee employment termination date to #{new_termination_date}" unless Rails.env.test?
      end
    rescue Exception => e
      puts e.message
    end
  end
end
