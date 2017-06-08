require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeCeTerminationDate < MongoidMigrationTask
  def migrate
    begin
      ce=CensusEmployee.by_ssn(ENV['ssn']).first
      dot = ENV['date_of_termination']
      if ce.nil?
        puts "No census employee was found with the given ssn"
      else
        ce.update_attributes(aasm_state:"employment_terminated")
        ce.update_attributes(employment_terminated_on: dot)
        puts "Terminated the census employee and change termination date to #{dot}" unless Rails.env.test?
      end
    rescue Exception => e
      puts e.message
    end
  end
end

