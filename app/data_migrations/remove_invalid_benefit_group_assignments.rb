
require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveInvalidBenefitGroupAssignments < MongoidMigrationTask
  def migrate
    organizations = Organization.where(fein: ENV['fein'])
    if organizations.size !=1
      raise 'Issues with the given fein'
    end
    benefit_group = organizations.first.employer_profile.plan_years.first.benefit_groups.first
    organizations.first.employer_profile.census_employees.each do |ce|
      ce.benefit_group_assignments.to_a.each do |bga|
        bga.delete if bga.hbx_enrollments.blank?
      end
      ce.benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: benefit_group, start_on: benefit_group.start_on, is_active: true)
      ce.save
    end
  end
end
