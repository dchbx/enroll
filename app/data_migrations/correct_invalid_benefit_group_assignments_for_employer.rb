
require File.join(Rails.root, "lib/mongoid_migration_task")

class CorrectInvalidBenefitGroupAssignmentsForEmployer < MongoidMigrationTask

  def organizations
    if ENV['fein'].present?
      Organization.where(fein: ENV['fein'])
    else
      Organization.exists(:employer_profile => true)
    end
  end
  
  def migrate  
    organizations.each do |org|
      org.employer_profile.census_employees.each do |ce|
        ce.benefit_group_assignments.each do |bga|
          benefit_group = bga.benefit_group

          if benefit_group.blank?
            bga.delete
            puts "Deleting invalid benefit group assignments for #{ce.first_name} #{ce.last_name} for ER with legal name #{organizations.first.legal_name}" unless Rails.env.test?
            next
          end

          if !(benefit_group.start_on..benefit_group.end_on).cover?(bga.start_on)
            bga.update_attribute(:start_on, [bga.benefit_group.start_on, ce.hired_on].compact.max)
            puts "Updating the start date of benefit group assignment for #{ce.first_name} #{ce.last_name} for ER with legal name #{organizations.first.legal_name}" unless Rails.env.test?
          end
          
          next if bga.end_on.blank?

          if !(benefit_group.start_on..benefit_group.end_on).cover?(bga.end_on) || bga.end_on < bga.start_on
            bga.update_attribute(:end_on, bga.benefit_group.end_on)
            puts "Updating the end date of benefit group assignment for #{ce.first_name} #{ce.last_name} for ER with legal name #{organizations.first.legal_name}" unless Rails.env.test?
          end
        end
      end
    end
  end
end
