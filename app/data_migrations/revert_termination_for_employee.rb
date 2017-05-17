require File.join(Rails.root, "lib/mongoid_migration_task")

class RevertTerminationForEmployee < MongoidMigrationTask
  def migrate
    begin
      census_employee = CensusEmployee.where(_id: ENV["census_employee_id"].to_s).first
      if census_employee.may_reinstate_eligibility?
        census_employee.reinstate_eligibility!
        census_employee.unset(:employment_terminated_on, :coverage_terminated_on)
        puts "Reverted Employee Termination" unless Rails.env.test?
        puts "Removed Employment termination on & coverage Termination On dates" unless Rails.env.test?
      else
        puts "Employee Not eligible for re-instatement" unless Rails.env.test?
      end

      if ENV['enrollment_hbx_id'].present?
        enrollment = HbxEnrollment.by_hbx_id(ENV['enrollment_hbx_id'].to_s)[0]
        if enrollment.termination_attributes_cleared?
          enrollment.update_attributes!(aasm_state: "coverage_enrolled") # No Event Available
          puts "Moved Enrollment to Enrolled status" unless Rails.env.test?
        end
      end
    rescue => e
      puts "#{e}"
    end
  end
end
