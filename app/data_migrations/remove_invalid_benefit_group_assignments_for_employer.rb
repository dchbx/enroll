
require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveInvalidBenefitGroupAssignmentsForEmployer < MongoidMigrationTask
  def migrate
    feins=ENV['fein'].split(",")
    feins.each do |fein|
      organization = Organization.where(fein: fein)
      if organization.size == 1 && organization.first.employer_profile.present?
        organization.first.employer_profile.census_employees.each do |ce|
          ce.benefit_group_assignments.select { |bga| bga.hbx_enrollments.blank? && bga.benefit_group.blank? }.each do |bga|
            bga.delete if bga.present?
            puts "Deleting invalid benefit group assignments for #{ce.first_name} #{ce.last_name} " unless Rails.env.test?
          end
        end
      else
        puts "*************Issues with the fein=#{fein}*******************" unless Rails.env.test?
      end
    end
  end
end
