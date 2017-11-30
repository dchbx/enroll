require File.join(Rails.root, "lib/mongoid_migration_task")

class TerminateACensusEmployee < MongoidMigrationTask
  def migrate
    census_employee = CensusEmployee.where(id:ENV['id']).first
    termination_date = Date.strptime(ENV['termination_date'].to_s, "%m/%d/%Y") if ENV['termination_date'].present?
    if census_employee.nil?
      puts "No census employee was found by the given id" unless Rails.env.test?
    else
      census_employee.terminate_employment(termination_date || 5.days.ago)
      puts "Terminated the census employee" unless Rails.env.test?
  	end
  end
end