
require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateInvalidBenefitGroupAssignmentsForEmployer < MongoidMigrationTask
  
  def migrate
    # organizations = Organization.all.first
    organizations = Organization.where(fein: ENV['fein'])
    if organizations.size !=1
      'Issues with fein'
      return
    end
    ces = organizations.first.employer_profile.census_employees.map(&:id)
    # puts "@@@@@@@@--- #{ces}"
    for i in 0..(ces.length - 1)
      ce = CensusEmployee.find(ces[i])
      # puts ce.inspect
      benefit_group_assignments = ce.benefit_group_assignments
      # puts ce.benefit_group_assignments.count
      benefit_group_assignments.each do |bga|
        # puts bga.inspect, bga.valid?
       if !bga.valid?
         if bga.hbx_enrollment && bga.hbx_enrollment.benefit_group.present?
           puts "Updating benefit group id on enrollment for #{ce.first_name} #{ce.last_name}"
           bga.hbx_enrollment.update_attributes(benefit_group_id: bga.benefit_group.id)
        end
      end
     end
    end
  end
end
