require File.join(Rails.root, "lib/mongoid_migration_task")
class ChangeCensusEmployeeDot < MongoidMigrationTask
  def migrate
    begin
      ce=CensusEmployee.where(id:ENV['census_employee_id']).first
      dot = Date.strptime(ENV['new_dot'].to_s, "%m/%d/%Y")
      if ce.nil?
        puts "No census employee was found with the given id" unless Rails.env.test?
      elsif ce.aasm_state != "employment_terminated"
        ce.update_attributes(aasm_state:"employment_terminated")
        ce.update_attributes(employment_terminated_on: dot)
        puts "Changed census employee to termination state and employment new dot to #{dot}" unless Rails.env.test?
      else
        ce.update_attributes(employment_terminated_on: dot)
        puts "Changed census employee employment new dot to #{dot}" unless Rails.env.test?
      end
    rescue Exception => e
      puts e.message
    end
  end
end
