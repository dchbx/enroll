
require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateCeEmploymentTerminatedOn < MongoidMigrationTask
  def migrate
    begin
      ce = CensusEmployee.where(id: ENV['ce_id'].to_s).first
      new_terminated_on = Date.strptime(ENV['new_employment_termination_date'].to_s, "%m/%d/%Y")
      if ce.nil?
        puts "No census employee was found the given id" unless Rails.env.test?
        return
      end
      ce.update_attributes(aasm_state:"employment_terminated")
      ce.update_attributes(employment_terminated_on:new_terminated_on)
      ce.errors
      puts "Changed employment terminated date to #{new_terminated_on}" unless Rails.env.test?
    rescue => e
      puts "Error for Census Employee with id: #{ce}. Error: #{e.message}"
    end
  end
end


