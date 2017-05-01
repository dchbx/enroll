
require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateBenefitGroupAssignmentStartDate < MongoidMigrationTask

  def migrate
    organizations = Organization.where(fein: ENV['fein'])
    if organizations.size !=1
      puts 'Issues with fein'
      return
    end
    ces = organizations.first.employer_profile.census_employees.map(&:id)
    for i in 0..(ces.length - 1)
      ce = CensusEmployee.find(ces[i])
      benefit_group_assignments = ce.benefit_group_assignments 
      begin
        benefit_group_assignments.each do |benefit_group_assignment|
          if !benefit_group_assignment.valid?
            plan_year = benefit_group_assignment.plan_year
            if plan_year.start_on != benefit_group_assignment.start_on
              benefit_group_assignment.update_attributes(start_on: plan_year.start_on)
              puts "Updating benefit group assignment start on for #{ce.first_name} #{ce.last_name}" unless Rails.env.test?
            end
          end 
        end
      rescue => e
        puts "Exception: #{e}, CensusEmployee: #{ce.first_name} #{ce.last_name}" unless Rails.env.test?
      end
    end
  end
end


