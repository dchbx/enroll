# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateBenefitGroupId < MongoidMigrationTask
  def migrate
    enrollment_hbx_id = ENV['enrollment_hbx_id']
    benefit_package_id = ENV['benefit_package_id'].to_s
    hbx_enrollment = HbxEnrollment.by_hbx_id(enrollment_hbx_id)
    if hbx_enrollment.first.nil?
      puts "No Enrollment was found with given hbx_id" unless Rails.env.test?
    elsif hbx_enrollment.first.benefit_package_id.present?
      puts " This HbxEnrollment has a benefit package which is not nil" unless Rails.env.test?
    else
      hbx_enrollment.first.update_attributes!(benefit_package_id: benefit_package_id)
      puts("This HBX enrollment's benefit ID was not nil and was updated.") unless Rails.env.test?
    end
  rescue StandardError => e
    puts e.to_s unless Rails.env.test?
  end
end
