require File.join(Rails.root, "lib/mongoid_migration_task")

class TerminateCobraEnrollment < MongoidMigrationTask
  def migrate
  census_employees = CensusEmployee.where(:aasm_state  => { "$in" => ["cobra_eligible","cobra_linked"]} , 
                                          :cobra_end_date => { "$lt" => TimeKeeper.date_of_record } )
   census_employees.each do |census_employee|
    benefit_groups = census_employee.active_and_renewing_benefit_group_assignments
    benefit_groups.each do |bg| 
      bg.hbx_enrollment.schedule_coverage_termination!
    end
   end
  end
end
