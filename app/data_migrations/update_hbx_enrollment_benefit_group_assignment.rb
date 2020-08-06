# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateHbxEnrollmentBenefitGroupAssignment < MongoidMigrationTask
  def migrate
    benefit_group_assignment_id = ENV['benefit_group_assignment_id'].to_s
    enrollment = HbxEnrollment.by_hbx_id(ENV['hbx_id'].to_s).first
    if enrollment.present?
      enrollment.update_attributes!(benefit_group_assignment_id: benefit_group_assignment_id)
      puts "Enrollment: #{enrollment.id}" unless Rails.env.test?
    else
      puts "No enrollment found" unless Rails.env.test?
    end
  end
end
