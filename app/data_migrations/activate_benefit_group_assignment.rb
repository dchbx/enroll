require File.join(Rails.root, "lib/mongoid_migration_task")

class ActivateBenefitGroupAssignment < MongoidMigrationTask
  def migrate
    begin
      census_employee = CensusEmployee.by_ssn(ENV['ce_ssn']).first
      if census_employee.nil?
        puts "No census employee was found with given ssn"
      else
        benefit_group_assignment=census_employee.benefit_group_assignments.where(id:ENV['bga_id']).first
        benefit_group_assignment.make_active
      end
    rescue => e
      e.message
    end

  end
end
