require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdateCeSsn < MongoidMigrationTask
  def migrate
    ce_id = ENV['ce_id']
    encrypted_ssn = ENV['encrypted_ssn']
    census_employee = CensusEmployee.where(_id: ce_id.first)
    if census_employee.present?
      census_employee.encrypted_ssn = encrypted_ssn
      census_employee.save(:validate => false)
      puts "changed the ssn" unless Rails.env.test?
    else
      puts "no census found for the input id" unless Rails.env.test?
    end
  end
end