# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateIVLOpenEnrollmentDates < MongoidMigrationTask
  def migrate
    benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship

    raise "Please provide title to find the correct benefit coverage period" if ENV['title'].blank?

    bcp = benefit_sponsorship.benefit_coverage_periods.where(title: ENV['title']).first

    bcp.update_attributes!(open_enrollment_start_on: Date.strptime((ENV['new_oe_start_date']).to_s, "%m/%d/%Y")) if ENV['new_oe_start_date'].present?
    bcp.update_attributes!(open_enrollment_end_on: Date.strptime((ENV['new_oe_end_date']).to_s, "%m/%d/%Y")) if ENV['new_oe_end_date'].present?

    puts "Updated Open Enrollment dates" unless Rails.env.test?
  rescue StandardError => e
    Rails.logger.error { "unable to update open enrollment dates due to #{e}" }
  end
end
