
require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeEnrollmentDetails < MongoidMigrationTask
  def migrate
    enrollment = get_enrollment
    action = ENV['action'].to_s

    case action
    when "change_effective_date"
      change_effective_date(enrollment)
    when "revert_termination"
      revert_termination(enrollment)
    when "terminate"
      terminate_enrollment(enrollment)
    end
  end

  def get_enrollment
    enrollments = HbxEnrollment.by_hbx_id(ENV['hbx_id'].to_s)
    if enrollments.size != 1
      raise "Found no (OR) more than 1 enrollments with the given hbx id" unless Rails.env.test?
    end
    enrollments.first
  end

  def change_effective_date(enrollment)
    if ENV['new_effective_on'].blank?
      raise "Input required: effective on" unless Rails.env.test?
    end
    new_effective_on = Date.strptime(ENV['new_effective_on'].to_s, "%m/%d/%Y")
    enrollment.update_attributes!(:effective_on => new_effective_on)
    puts "Changed Enrollment effective on date to #{new_effective_on}" unless Rails.env.test?
  end

  def revert_termination(enrollment)
    enrollment.update_attributes!(terminated_on: nil, termination_submitted_on: nil, aasm_state: "coverage_selected")
    enrollment.hbx_enrollment_members.each { |mem| mem.update_attributes!(coverage_end_on: nil)}
    puts "Reverted Enrollment termination" unless Rails.env.test?
  end

  def terminate_enrollment(enrollment)
    terminated_on = Date.strptime(ENV['terminated_on'].to_s, "%m/%d/%Y")
    enrollment.update_attributes!(terminated_on: terminated_on, termination_submitted_on:TimeKeeper.date_of_record, aasm_state: "coverage_terminated")
    puts "terminate enrollment on #{terminated_on}" unless Rails.env.test?
  end
end
