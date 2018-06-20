module Factories
  module EnrollmentRenewalBuilder

    def generate_passive_renewal(options = {})
      if renewal_plan_offered_by_er?(enrollment)
        renewal_enrollment = family.active_household.hbx_enrollments.new
        renewal_enrollment = assign_common_attributes(enrollment, renewal_enrollment)
        renewal_enrollment = clone_shop_enrollment(enrollment, renewal_enrollment)
        # renewal_enrollment.send(options.fetch(:aasm_event, :renew_enrollment))
        # renewal_enrollment.decorated_hbx_enrollment
        save_renewal_enrollment(renewal_enrollment, enrollment, options)
      end
    end

    def save_renewal_enrollment(renewal_enrollment, active_enrollment, options={})
      if renewal_enrollment.save # This will generate hbx_id to enrollment
        renewal_enrollment.send(options.fetch(:aasm_event, :renew_enrollment)) # After save, so that it will handle state machine hooks
        renewal_enrollment.save
        renewal_enrollment
      else
        message = "Enrollment: #{active_enrollment.id}, \n" \
        "Unable to save renewal enrollment: #{renewal_enrollment.inspect}, \n" \
          "Error(s): \n #{renewal_enrollment.errors.map{|k,v| "#{k} = #{v}"}.join(" & \n")} \n"

        Rails.logger.error { message }
        raise ShopEnrollmentRenewalFactoryError, message
      end
    end

    def assign_common_attributes(active_enrollment, renewal_enrollment)
      common_attributes = %w(coverage_household_id coverage_kind changing broker_agency_profile_id
          writing_agent_id original_application_type kind special_enrollment_period_id
        )
      common_attributes.each do |attr|
         renewal_enrollment.send("#{attr}=", active_enrollment.send(attr))
      end

      renewal_enrollment.plan_id = active_enrollment.plan.renewal_plan_id if active_enrollment.plan.present?
      renewal_enrollment
    end

    def clone_shop_enrollment(active_enrollment, renewal_enrollment)
      # Find and associate with new ER benefit group

      benefit_group_assignment = renewal_assignment

      if benefit_group_assignment.blank?
        message = "Unable to find benefit_group_assignment for census_employee: \n"\
          "census_employee: #{@census_employee.full_name} "\
          "id: #{@census_employee.id} "\
          "for hbx_enrollment #{active_enrollment.id}"

        Rails.logger.error { message }
        raise ShopEnrollmentRenewalFactoryError, message
      end

      renewal_enrollment.benefit_group_assignment_id = benefit_group_assignment.id
      renewal_enrollment.benefit_group_id = benefit_group_assignment.benefit_group_id

      renewal_enrollment.employee_role_id = active_enrollment.employee_role_id
      renewal_enrollment.effective_on = benefit_group_assignment.benefit_group.start_on
      renewal_enrollment.kind = active_enrollment.kind if active_enrollment.is_cobra_status?
      # Set the HbxEnrollment to proper state

      # Renew waiver status
      if active_enrollment.is_coverage_waived?
        renewal_enrollment.waiver_reason = active_enrollment.waiver_reason
        renewal_enrollment.waive_coverage
      end

      renewal_enrollment.hbx_enrollment_members = clone_enrollment_members(active_enrollment, renewal_enrollment)
      renewal_enrollment
    end

    # clone enrollment members if relationship offered in renewal plan year and active in current hbxenrollment
    def clone_enrollment_members(active_enrollment, renewal_enrollment)
      hbx_enrollment_members = active_enrollment.hbx_enrollment_members
      hbx_enrollment_members.reject!{|member| !is_relationship_offered_and_member_covered?(member,renewal_enrollment) }
      hbx_enrollment_members.inject([]) do |members, hbx_enrollment_member|
        members << HbxEnrollmentMember.new({
          applicant_id: hbx_enrollment_member.applicant_id,
          eligibility_date: @plan_year_start_on,
          coverage_start_on: @plan_year_start_on,
          is_subscriber: hbx_enrollment_member.is_subscriber
        })
      end
    end

    # relationship_benefits of renewal plan year
    def renewal_relationship_benefits(renewal_enrollment)
      benefit_group = renewal_assignment.benefit_group
      if renewal_enrollment.coverage_kind == "health"
        benefit_group.relationship_benefits.select(&:offered).map(&:relationship)
      else
        benefit_group.dental_relationship_benefits.select(&:offered).map(&:relationship)
      end
    end

    # relationship offered in renewal plan year and member active in enrollment.
    def is_relationship_offered_and_member_covered?(member,renewal_enrollment)
      relationship = PlanCostDecorator.benefit_relationship(member.primary_relationship)
      relationship = "child_over_26" if relationship == "child_under_26" && member.person.age_on(@plan_year_start_on) >= 26
      (renewal_relationship_benefits(renewal_enrollment).include?(relationship) && member.is_covered_on?(@plan_year_start_on - 1.day))
    end

    # Validate enrollment membership against benefit package-covered relationships
    def family_eligibility(active_enrollment, renewal_enrollment)
      coverage_household.coverage_household_members.each do |coverage_member|
        enrollment_member = HbxEnrollmentMember.new_from(coverage_household_member: coverage_member)
        enrollment_member.eligibility_date = enrollment.effective_on
        enrollment_member.coverage_start_on = enrollment.effective_on
        renewal_enrollment.hbx_enrollment_members << enrollment_member
      end

      renewal_enrollment.hbx_enrollment_members
    end

    def renew_waived_enrollment
      renewal_enrollment = family.active_household.hbx_enrollments.new

      renewal_enrollment.coverage_kind = enrollment.try(:coverage_kind) || coverage_kind || "health"
      renewal_enrollment.enrollment_kind = "open_enrollment"
      renewal_enrollment.kind = enrollment.try(:kind) || "employer_sponsored"

      benefit_group_assignment = renewal_assignment

      if benefit_group_assignment.blank?
        message = "Unable to find benefit_group_assignment for census_employee: \n"\
          "census_employee: #{@census_employee.full_name} "\
          "id: #{@census_employee.id} "

        Rails.logger.error { message }
        raise ShopEnrollmentRenewalFactoryError, message
      end

      renewal_enrollment.benefit_group_assignment_id = benefit_group_assignment.id
      renewal_enrollment.benefit_group_id = benefit_group_assignment.benefit_group_id
      renewal_enrollment.effective_on = benefit_group_assignment.benefit_group.start_on
      renewal_enrollment.employee_role_id = @census_employee.employee_role_id
      renewal_enrollment.waiver_reason = enrollment.try(:waiver_reason) || "I do not have other coverage"
      renewal_enrollment.renew_waived
      renewal_enrollment.submitted_at = TimeKeeper.datetime_of_record

      if renewal_enrollment.save
        return
      else
        message = "Unable to save waived renewal enrollment: #{renewal_enrollment.inspect}, \n" \
          "Error(s): \n #{renewal_enrollment.errors.map{|k,v| "#{k} = #{v}"}.join(" & \n")} \n"

          Rails.logger.error { message }

        raise ShopEnrollmentRenewalFactoryError, message
      end
    end
  end
end
