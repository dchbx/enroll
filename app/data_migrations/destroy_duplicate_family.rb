# frozen_string_literal: true

require File.join(Rails.root,"lib/mongoid_migration_task")

class DestroyDuplicateFamily < MongoidMigrationTask

  def migrate
    family_id = ENV['family_id']
    family = Family.find(family_id)
    valid_enrollment_state = HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES + HbxEnrollment::TERMINATED_STATUSES + HbxEnrollment::SELECTED_AND_WAIVED
    enrollments = family.active_household.hbx_enrollments.detect {|hbx_enrollment| valid_enrollment_state.include?(hbx_enrollment.aasm_state)}

    if enrollments.present?
      puts "Family has valid enrollment in account please check" unless Rails.env.test?
    else
      family.destroy!
      puts "Invalid family destroyed" unless Rails.env.test?
    end
  end
end
