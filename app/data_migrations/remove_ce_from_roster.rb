require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveCeFromRoster < MongoidMigrationTask
  def migrate
    ce_id = ENV['ce_id']
    ce=CensusEmployee.find(ce_id)
    if ce.nil?
      puts 'no census employee was found with given id #{ce_id} ' unless Rails.env.test?
      return
    else
      unless ce.employee_role.nil?
        ce.employee_role.unset(:census_employee_id)
      end
      ce.delete
      puts 'the census employee with id #{ce_id} has been removed from the roster ' unless Rails.env.test?
    end
  end
end
