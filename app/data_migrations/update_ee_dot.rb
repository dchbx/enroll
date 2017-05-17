require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateEeDot < MongoidMigrationTask
  def migrate
    begin
      id = (ENV['id']).to_s
      employment_terminated_on = Date.strptime(ENV['employment_terminated_on'].to_s, "%m/%d/%Y")
      CensusEmployee.where(id: id).first.update_attribute(:employment_terminated_on, employment_terminated_on)
      puts "Changed Date of Termination to #{employment_terminated_on}" unless Rails.env.test?
    rescue
      puts "Bad Employee Record" unless Rails.env.test?
    end
  end
end