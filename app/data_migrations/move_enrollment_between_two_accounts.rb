require File.join(Rails.root,"lib/mongoid_migration_task")
class MoveEnrollmentBetweenTwoAccount < MongoidMigrationTask
  def migrate
    new_account_hbx_id = ENV['new_account_hbx_id']
    old_account_hbx_id = ENV['old_account_hbx_id']
    enr_id = ENV['enrollment_hbx_id'].to_s
    gp = Person.where(hbx_id:new_account_hbx_id).first
    bp = Person.where(hbx_id:old_account_hbx_id).first
    hbx_enrollment = HbxEnrollment.by_hbx_id(enr_id).first

    if gp.nil? || bp.nil?
      puts "Check Input. Found No person records" unless Rails.env.test?
      return
    elsif hbx_enrollment.nil?
      puts "No Enrollment found with given hbx Id" unless Rails.env.test?
      return
    end

    if hbx_enrollment.is_shop?
      employee_role = gp.employee_roles.detect { |er| er.employer_profile_id == hbx_enrollment.employee_role.employer_profile.id}
      if employee_role.blank?
        puts "New person don't have ER sponsored benefits related to Enrollment" unless Rails.env.test?
        return
      end

      benefit_group_assignment = employee_role.census_employee.benefit_group_assignments.detect { |bga| bga.benefit_group_id == hbx_enrollment.benefit_group_id}
      if benefit_group_assignment.blank?
        puts "No Benefit Group Assignment Found" unless Rails.env.test?
        return
      end

      employee_role_id = employee_role.id
      benefit_group_assignment_id = benefit_group_assignment.id
      consumer_role_id = nil
    else
      consumer_role_id = gp.consumer_role.id
      employee_role_id = nil
    end


    enrollment = HbxEnrollment.new( kind: hbx_enrollment.kind, enrollment_kind: hbx_enrollment.enrollment_kind,
                                    employee_role_id: employee_role_id, benefit_group_id: hbx_enrollment.benefit_group_id,
                                    benefit_group_assignment_id: benefit_group_assignment_id, effective_on: hbx_enrollment.effective_on,
                                    plan_id: hbx_enrollment.plan_id, aasm_state: hbx_enrollment.aasm_state, hbx_id: hbx_enrollment.hbx_id,
                                    coverage_kind: hbx_enrollment.coverage_kind, elected_amount: hbx_enrollment.elected_amount,
                                    elected_premium_credit: hbx_enrollment.elected_premium_credit, applied_premium_credit: hbx_enrollment.applied_premium_credit,
                                    elected_aptc_pct: hbx_enrollment.elected_aptc_pct, applied_aptc_amount: hbx_enrollment.applied_aptc_amount,
                                    changing: hbx_enrollment.changing, terminated_on: hbx_enrollment.terminated_on,
                                    terminate_reason: hbx_enrollment.terminate_reason, carrier_profile_id: hbx_enrollment.carrier_profile_id,
                                    special_enrollment_period_id: hbx_enrollment.special_enrollment_period_id, enrollment_signature: hbx_enrollment.enrollment_signature,
                                    aasm_state_date: hbx_enrollment.aasm_state_date, submitted_at: hbx_enrollment.submitted_at,
                                    original_application_type: hbx_enrollment.original_application_type, consumer_role_id: consumer_role_id,
                                    benefit_package_id: hbx_enrollment.benefit_package_id,
                                    benefit_coverage_period_id: hbx_enrollment.benefit_coverage_period_id, updated_by: hbx_enrollment.updated_by,
                                    is_active: hbx_enrollment.is_active, waiver_reason: hbx_enrollment.waiver_reason,
                                    published_to_bus_at: hbx_enrollment.published_to_bus_at, review_status: hbx_enrollment.review_status,
                                    special_verification_period: hbx_enrollment.special_verification_period, termination_submitted_on: hbx_enrollment.termination_submitted_on,
                                    external_enrollment: hbx_enrollment.external_enrollment
                                  )

    family_members = gp.primary_family.active_family_members.select { |fm| Family::IMMEDIATE_FAMILY.include? fm.primary_relationship }
    family_members.each do |fm|
      hem = HbxEnrollmentMember.new(applicant_id: fm.id, is_subscriber: fm.is_primary_applicant,
                                    eligibility_date: hbx_enrollment.effective_on, coverage_start_on: hbx_enrollment.effective_on
                                   )
      enrollment.hbx_enrollment_members << hem
    end


    hbx_enrollment.destroy!
    gp.primary_family.active_household.hbx_enrollments << enrollment
    gp.primary_family.active_household.save!
    puts "Hbx Enrollment succesfully moved!!" unless Rails.env.test?
    puts "Confirm the people under covered section on the enrollment!!" unless Rails.env.test?
  end
end
