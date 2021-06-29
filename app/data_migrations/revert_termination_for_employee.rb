# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class RevertTerminationForEmployee < MongoidMigrationTask
  def migrate
    census_employee = CensusEmployee.where(_id: ENV["census_employee_id"].to_s).first
    if census_employee.may_reinstate_eligibility?
      census_employee.reinstate_eligibility!
    else
      from_state = census_employee.aasm_state
      census_employee.update_attributes(aasm_state: "employee_role_linked")
      census_employee.workflow_state_transitions << WorkflowStateTransition.new(from_state: from_state, to_state: census_employee.aasm_state)
    end
    census_employee.unset(:employment_terminated_on, :coverage_terminated_on)
    puts "Reverted Employee Termination" unless Rails.env.test?


    hbx_ids = (ENV['enrollment_hbx_id']).to_s.split(',').uniq
    @enrollments = []
    hbx_ids.each do |hbx_id|
      raise "Found no (OR) more than 1 enrollments with the #{hbx_id}" if HbxEnrollment.by_hbx_id(hbx_id.to_s).size != 1 && !Rails.env.test?
      @enrollments << HbxEnrollment.by_hbx_id(hbx_id.to_s).first
    end
    @enrollments.each do |enrollment|
      state = enrollment.aasm_state
      enrollment.update_attributes!(terminated_on: nil, terminate_reason: nil, termination_submitted_on: nil, aasm_state: "coverage_enrolled")
      enrollment.workflow_state_transitions << WorkflowStateTransition.new(
        from_state: state,
        to_state: "coverage_enrolled"
      )

      enrollment.hbx_enrollment_members.each { |mem| mem.update_attributes!(coverage_end_on: nil)}
      puts "Reverted Enrollment termination" unless Rails.env.test?
    end
  rescue StandardError => e
    puts e.to_s
  end
end
