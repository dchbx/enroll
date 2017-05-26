require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateEeDependentSSN < MongoidMigrationTask
  def migrate
    census_employee = CensusEmployee.where(_id: ENV['ce_id']).first
    if census_employee.census_dependents.present?
      dep = census_employee.census_dependents.where(_id: ENV['dep_id']).first
      if dep.present?
        dep.update_attributes!(ssn: ENV['dep_ssn'])
        puts "SSN of census_employee: #{census_employee.full_name}'s dependent: #{dep.full_name} updated to '#{ENV['dep_ssn']}' " unless Rails.env.test?
      else
        puts "dependent id not found"
      end
    else
      puts "no census_dependents found for census_employee"
    end
  end
end
