# frozen_string_literal: true

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
      cancel_enrollment(enrollments)
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
    when "create_enrollment_for_benefit_application"
      create_enrollment_for_benefit_application(enrollments)
    end
  end

  def get_enrollment
    hbx_ids = (ENV['hbx_id']).to_s.split(',').uniq
    hbx_ids.inject([]) do |enrollments, hbx_id|
      raise "Found no (OR) more than 1 enrollments with the #{hbx_id}" if HbxEnrollment.by_hbx_id(hbx_id.to_s).size != 1 && !Rails.env.test?
      enrollments << HbxEnrollment.by_hbx_id(hbx_id.to_s).first
    end
  end

  def change_effective_date(enrollments)
    raise "Input required: effective on" if ENV['new_effective_on'].blank? && !Rails.env.test?
    new_effective_on = Date.strptime(ENV['new_effective_on'].to_s, "%m/%d/%Y")
    enrollments.each do |enrollment|
      enrollment.update_attributes!(:effective_on => new_effective_on)
      puts "Changed Enrollment effective on date to #{new_effective_on}" unless Rails.env.test?
    end
  end

  def change_plan(enrollments)
    raise "Input required: plan id" if ENV['new_product_id'].blank? && !Rails.env.test?
    new_product_id = ENV['new_product_id']
    enrollments.each do |enrollment|
      enrollment.update_attributes!(:product_id => new_product_id)
      puts "Changed Enrollment's plan to #{new_product_id}" unless Rails.env.test?
    end
  end

  def change_benefit_group(enrollments)
    raise "Input required: benefit group id" if ENV['new_sponsored_benefit_package_id'].blank? && !Rails.env.test?
    new_sponsored_benefit_package_id = ENV['new_sponsored_benefit_package_id']
    enrollments.each do |enrollment|
      enrollment.update_attributes!(:sponsored_benefit_package_id => new_sponsored_benefit_package_id)
      puts "Changed Enrollment's benefit group to #{new_sponsored_benefit_package_id}" unless Rails.env.test?
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

  def cancel_enrollment(enrollments)
    enrollments.each do |enrollment|
      enrollment.update_attributes(aasm_state: "coverage_canceled")
      puts "enrollment with hbx_id: #{enrollment.hbx_id} cancelled" unless Rails.env.test?
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
      enrollment.update_attributes(aasm_state: "coverage_expired")
      puts "expire enrollment with hbx_id: #{enrollment.hbx_id}" unless Rails.env.test?
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

  # creates new enrollment with given enrollment details with effective date as benefit application start date.
  def create_enrollment_for_benefit_application(enrollments)
    benefit_sponsorship = BenefitSponsors::Organizations::Organization.employer_profiles.where(fein: ENV['fein']).first.active_benefit_sponsorship
    benefit_application = benefit_sponsorship.benefit_applications.where(:'effective_period.min' => Date.strptime(ENV['start_on'].to_s, "%m/%d/%Y")).first
    benefit_package = benefit_application.benefit_packages.first

    enrollments.each do |enrollment|

      new_enrollment = BenefitSponsors::Factories::EnrollmentRenewalFactory.call(enrollment, benefit_package)
      if  new_enrollment.present? && new_enrollment.valid?

        new_enrollment.save!

        assignment = enrollment.employee_role.census_employee.benefit_group_assignment_by_package(new_enrollment.sponsored_benefit_package_id, new_enrollment.effective_on)
        assignment.update_attributes(hbx_enrollment_id: new_enrollment.id)

        new_enrollment.select_coverage! if new_enrollment.may_select_coverage?
        new_enrollment.begin_coverage! if new_enrollment.may_begin_coverage?

        puts "New enrollment created " unless Rails.env.test?
      else
        puts "Unable to save new enrollment " unless Rails.env.test?
      end

    end
  end

  def transfer_enrollment_from_glue_to_enroll
    # This method needs to be updated to new model
    ts = if ENV['market'].present?
           TranscriptGenerator.new(ENV['market'].to_s)
         else
           TranscriptGenerator.new
         end
    ts.display_enrollment_transcripts
  end
end
