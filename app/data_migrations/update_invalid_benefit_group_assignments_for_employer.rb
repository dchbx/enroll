
require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateInvalidBenefitGroupAssignmentsForEmployer < MongoidMigrationTask
  
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
      benefit_group_assignments.each do |bga|
        begin
         if !bga.valid?
           if bga.hbx_enrollment && bga.hbx_enrollment.benefit_group_id != bga.benefit_group.id
             puts "Updating benefit group id on enrollment for #{ce.first_name} #{ce.last_name}" unless Rails.env.test?
             bga.hbx_enrollment.update_attributes!(benefit_group_id: bga.benefit_group.id)
           end
         end
        rescue => e
          puts "Exception: #{e}, CensusEmployee: #{ce.first_name} #{ce.last_name}" unless Rails.env.test?
        end
     end
    end
  end
end
