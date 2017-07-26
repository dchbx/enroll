require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveTerminationDateFromEnrollment < MongoidMigrationTask
  def migrate
    enrollment_hbx_id = ENV['enrollment_hbx_id']
    enrollment = HbxEnrollment.by_hbx_id(enrollment_hbx_id).first
    if enrollment.nil?
      puts "No hbx_enrollment was found with the given hbx_id" unless Rails.env.test?
    else
      enrollment.unset(:terminated_on)
      state = enrollment.aasm_state
      if enrollment.update_attributes(aasm_state:"coverage_selected")
        enrollment.workflow_state_transitions << WorkflowStateTransition.new(
            from_state: state,
            to_state: "coverage_selected"
        )
      end
    end
  end
end
