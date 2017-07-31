require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateInvalidBenefitGroupAssignmentForCensusEmployee < MongoidMigrationTask
  def migrate
    begin
      census_employee = CensusEmployee.where(_id: ENV["census_employee_id"].to_s).first
      census_employee.benefit_group_assignments.each do |bga|
        if bga.is_active? && !bga.valid?
          bga.update_attributes!(:aasm_state, 'coverage_expired', :is_active, false, :hbx_enrollment_id, nil)
          puts "Updated Benefit group assignment for Employee with id: #{employee_role_id}" unless Rails.env.test?
        end
      end   
    rescue => e
      puts "Exception: #{e}, CensusEmployee: #{ENV['census_employee_id']}" unless Rails.env.test? 
    end 
  end
end

