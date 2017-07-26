
require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeEnrollmentTerminationDate < MongoidMigrationTask
  def migrate
    enrollment = HbxEnrollment.by_hbx_id(ENV['hbx_id'].to_s)
    new_termination_date = Date.strptime(ENV['new_termination_date'].to_s, "%m/%d/%Y")
    enrollment.first.update_attributes(terminated_on: new_termination_date)
    enrollment_members = enrollment.first.hbx_enrollment_members
    unless enrollment_members.nil?
      enrollment_members.each do |member|
        member.update_attributes(coverage_end_on:new_termination_date)
      end
    end
    puts "Changed Enrollment termination date to #{new_termination_date}" unless Rails.env.test?
  end
end
