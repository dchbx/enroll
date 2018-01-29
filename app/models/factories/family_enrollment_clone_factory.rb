module Factories
  class FamilyEnrollmentCloneFactory
    include Mongoid::Document
    attr_accessor :family, :census_employee, :enrollment

    def clone_for_cobra
      raise ArgumentError if !defined?(family) || !defined?(census_employee)
      clone_enrollment = clone_cobra_enrollment
      clone_enrollment.decorated_hbx_enrollment
      save_clone_enrollment(clone_enrollment)
    end

    def save_clone_enrollment(clone_enrollment)
      if clone_enrollment.save
        clone_enrollment
      else
        message = "Enrollment: #{enrollment.id}, \n" \
        "Unable to save clone enrollment: #{clone_enrollment.inspect}, \n" \
          "Error(s): \n #{clone_enrollment.errors.map{|k,v| "#{k} = #{v}"}.join(" & \n")} \n"

        Rails.logger.error { message }
        raise FamilyEnrollmentCloneFactory, message
      end
    end

    def effective_on_for_cobra(enrollment)
      effective_on_by_terminated = census_employee.coverage_terminated_on.end_of_month + 1.days
      effective_on_by_benefit_group = enrollment.benefit_group.effective_on_for_cobra(census_employee.hired_on)
      [effective_on_by_terminated, effective_on_by_benefit_group].max
    end

    def clone_cobra_enrollment
      clone_enrollment = family.active_household.hbx_enrollments.new

      clone_enrollment.benefit_group_assignment_id = enrollment.benefit_group_assignment_id
      clone_enrollment.benefit_group_id = enrollment.benefit_group_id
      clone_enrollment.employee_role_id = enrollment.employee_role_id
      clone_enrollment.plan_id = enrollment.plan_id
      clone_enrollment.coverage_kind = enrollment.coverage_kind

      clone_enrollment.kind = 'employer_sponsored_cobra'
      effective_on = effective_on_for_cobra(enrollment)
      clone_enrollment.effective_on = effective_on
      clone_enrollment.external_enrollment = enrollment.external_enrollment

      if enrollment.benefit_group.plan_year.is_renewing?
        clone_enrollment.aasm_state = 'auto_renewing'
      else
        clone_enrollment.select_coverage
        if TimeKeeper.date_of_record >= effective_on && !enrollment.external_enrollment
          clone_enrollment.begin_coverage
        end
      end

      clone_enrollment.generate_hbx_signature
      clone_enrollment.hbx_enrollment_members = clone_enrollment_members
      clone_enrollment
    end

    def clone_enrollment_members
      hbx_enrollment_members = enrollment.hbx_enrollment_members
      effective_on = effective_on_for_cobra(enrollment)
      hbx_enrollment_members.inject([]) do |members, hbx_enrollment_member|
        members << HbxEnrollmentMember.new({
          applicant_id: hbx_enrollment_member.applicant_id,
          eligibility_date: effective_on,
          coverage_start_on: enrollment.effective_on,
          is_subscriber: hbx_enrollment_member.is_subscriber
        })
      end
    end
  end

  class FamilyEnrollmentCloneFactoryError < StandardError; end
end
