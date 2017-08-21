require File.join(Rails.root, "lib/mongoid_migration_task")
class ChangeAasmStateDotCensusEmployee < MongoidMigrationTask
  def migrate
    begin
      census_employee=CensusEmployee.where(id:ENV['census_employee_id']).first
      if census_employee.nil?
        puts "No census employee was found with the given id" unless Rails.env.test?
      else
        census_employee.update_attributes(aasm_state:"employee_role_linked",employment_terminated_on: nil ,coverage_terminated_on: nil)
        puts "Changed census employee aasm_state and dot" unless Rails.env.test?
      end
    rescue Exception => e
      puts e.message
    end
  end
end
