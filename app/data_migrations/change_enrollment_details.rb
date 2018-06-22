require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeEnrollmentDetails < MongoidMigrationTask
  def migrate
    enrollments = get_enrollment
    action = ENV['action'].to_s

    case action
      when "change_effective_date"
        change_effective_date(enrollments)
      when "revert_termination"
        revert_termination(enrollments)
      when "terminate"
        terminate_enrollment(enrollments)
      when "revert_cancel"
        # When Enrollment with given policy ID is active in Glue & canceled in Enroll(Mostly you will see this with passive enrollments)
        revert_cancel(enrollments)
      when "cancel", "cancel_enrollment"
        cancel_enr(enrollments)
      when "generate_hbx_signature"
        generate_hbx_signature(enrollments)
      when "expire_enrollment"
        expire_enrollment(enrollments)
      when "transfer_enrollment_from_glue_to_enroll"
        transfer_enrollment_from_glue_to_enroll
      when "change_plan"
        change_plan(enrollments)
      when "change_benefit_group"
        change_benefit_group(enrollments)
      when "change_enrollment_status"
        change_enrollment_status(enrollments)
    end
  end

  def get_enrollment
    hbx_ids = "#{ENV['hbx_id']}".split(',').uniq
    hbx_ids.inject([]) do |enrollments, hbx_id|
      if HbxEnrollment.by_hbx_id(hbx_id.to_s).size != 1
        raise "Found no (OR) more than 1 enrollments with the #{hbx_id}" unless Rails.env.test?
      end
      enrollments << HbxEnrollment.by_hbx_id(hbx_id.to_s).first
    end
  end

  def change_effective_date(enrollments)
    if ENV['new_effective_on'].blank?
      raise "Input required: effective on" unless Rails.env.test?
    end
    new_effective_on = Date.strptime(ENV['new_effective_on'].to_s, "%m/%d/%Y")
    enrollments.each do |enrollment|
      enrollment.update_attributes!(:effective_on => new_effective_on)
      puts "Changed Enrollment effective on date to #{new_effective_on}" unless Rails.env.test?
    end
  end

  def change_plan(enrollments)
    if ENV['new_plan_id'].blank?
      raise "Input required: plan id" unless Rails.env.test?
    end
    new_plan_id = ENV['new_plan_id']
    enrollments.each do |enrollment|
      enrollment.update_attributes!(:plan_id => new_plan_id)
      puts "Changed Enrollment's plan to #{new_plan_id}" unless Rails.env.test?
    end
  end

  def change_benefit_group(enrollments)
    if ENV['new_benefit_group_id'].blank?
      raise "Input required: benefit group id" unless Rails.env.test?
    end
    new_benefit_group_id = ENV['new_benefit_group_id']
    enrollments.each do |enrollment|
      enrollment.update_attributes!(:benefit_group_id => new_benefit_group_id)
      puts "Changed Enrollment's benefit group to #{new_benefit_group_id}" unless Rails.env.test?
    end
  end

  def revert_termination(enrollments)
    enrollments.each do |enrollment|
      state = enrollment.aasm_state
      if enrollment.is_shop?
        enrollment.update_attributes!(terminated_on: nil, termination_submitted_on: nil, aasm_state: "coverage_enrolled")
        enrollment.workflow_state_transitions << WorkflowStateTransition.new(
            from_state: state,
            to_state: "coverage_enrolled"
        )
      else
        enrollment.update_attributes!(terminated_on: nil, termination_submitted_on: nil, aasm_state: "coverage_selected")
        enrollment.workflow_state_transitions << WorkflowStateTransition.new(
            from_state: state,
            to_state: "coverage_selected"
        )
      end
      enrollment.hbx_enrollment_members.each {|mem| mem.update_attributes!(coverage_end_on: nil)}
      puts "Reverted Enrollment termination" unless Rails.env.test?
    end

  end

  def terminate_enrollment(enrollments)
    terminated_on = Date.strptime(ENV['terminated_on'].to_s, "%m/%d/%Y")
    enrollments.each do |enrollment|
      enrollment.update_attributes!(terminated_on: terminated_on, aasm_state: "coverage_terminated")
      puts "terminate enrollment on #{terminated_on}" unless Rails.env.test?
    end

  end

  def revert_cancel(enrollments)
    enrollments.each do |enrollment|
      enrollment.update_attributes(aasm_state: "coverage_enrolled")
      puts "Moved enrollment to Enrolled status from canceled state" unless Rails.env.test?
    end
  end

  def cancel_enr(enrollments)
    enrollments.each do |enrollment|
      if enrollment.may_cancel_coverage?
        enrollment.cancel_coverage!
        puts "enrollment with hbx_id: #{enrollment.hbx_id} cancelled" unless Rails.env.test?
      else
        puts " Issue with enrollment with hbx_id: #{enrollment.hbx_id}" unless Rails.env.test?
      end
    end
  end

  def generate_hbx_signature(enrollments)
    enrollments.each do |enrollment|
      enrollment.generate_hbx_signature
      enrollment.save!
      puts "enrollment_signature generated #{enrollment.enrollment_signature}" unless Rails.env.test?
    end
  end

  def expire_enrollment(enrollments)
    enrollments.each do |enrollment|
      if enrollment.may_expire_coverage?
        enrollment.expire_coverage!
        puts "expire enrollment with hbx_id: #{enrollment.hbx_id}" unless Rails.env.test?
      else
        puts "HbxEnrollment with hbx_id: #{enrollment.hbx_id} can not be expired" unless Rails.env.test?
      end
    end
  end

  def change_enrollment_status(enrollments)
    new_aasm_state = ENV['new_aasm_state'].to_s
    puts "cannot move enrollments state old / new state missing" unless new_aasm_state.present?
    enrollments.each do |enrollment|
      if enrollment.send("may_#{new_aasm_state}?")
        enrollment.send("#{new_aasm_state}!")
        puts "AASM state changed for hbx_id: #{enrollment.hbx_id}" unless Rails.env.test?
      else
        puts "HbxEnrollment with hbx_id: #{enrollment.hbx_id} can not be moved to #{new_aasm_state}" unless Rails.env.test?
      end
    end
  end

  def transfer_enrollment_from_glue_to_enroll
    ts = TranscriptGenerator.new
    ts.display_enrollment_transcripts
  end
end
