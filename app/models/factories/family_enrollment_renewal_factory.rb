module Factories
  class FamilyEnrollmentRenewalFactory
    include Mongoid::Document

    # Renews a family's active enrollments from current plan year

    attr_accessor :family, :census_employee, :employer, :renewing_plan_year

    def renew
      raise ArgumentError unless defined?(@family)

      # excluded_states = %w(coverage_canceled, coverage_terminated unverified renewing_passive
      #                       renewing_coverage_selected renewing_transmitted_to_carrier renewing_coverage_enrolled
      #                     )
      # shop_enrollments = @family.enrollments.shop_market.reduce([]) { |list, e| excluded_states.include?(e.aasm_state) ? list : list << e } 

      ## Works only for data migrated into Enroll 
      ## FIXME add logic to support Enroll native renewals 

      return true if family.active_household.hbx_enrollments.any?{|enrollment| (HbxEnrollment::RENEWAL_STATUSES.include?(enrollment.aasm_state) || enrollment.renewing_waived?)}

      shop_enrollments  = @family.active_household.hbx_enrollments.enrolled.shop_market + @family.active_household.hbx_enrollments.waived
      return true if shop_enrollments.any? {|enrollment| enrollment.effective_on >= @renewing_plan_year.start_on }

      @plan_year_start_on = @renewing_plan_year.start_on
      prev_plan_year_start = @plan_year_start_on - 1.year
      prev_plan_year_end = @plan_year_start_on - 1.day

      shop_enrollments.reject! {|enrollment| !(prev_plan_year_start..prev_plan_year_end).cover?(enrollment.effective_on) }
      shop_enrollments.reject!{|enrollment| !enrollment.currently_active? }

      if shop_enrollments.compact.empty?
        renew_waived_enrollment
      else
        active_enrollment = shop_enrollments.compact.sort_by{|e| e.submitted_at || e.created_at }.last
        if active_enrollment.present? && active_enrollment.inactive?
          renew_waived_enrollment(active_enrollment)
        elsif renewal_plan_offered_by_er?(active_enrollment)
          renewal_enrollment = renewal_builder(active_enrollment)
          renewal_enrollment = clone_shop_enrollment(active_enrollment, renewal_enrollment)
          renewal_enrollment.decorated_hbx_enrollment
          save_renewal_enrollment(renewal_enrollment, active_enrollment)
        end
      end
     
      return @family
    end

    def renewal_plan_offered_by_er?(enrollment)
      if enrollment.plan.blank? || enrollment.plan.renewal_plan.blank?
        return false
      end

      renewal_assignment = @census_employee.renewal_benefit_group_assignment
      if renewal_assignment.blank?
        return false
      end

      renewal_assignment.benefit_group.elected_plan_ids.include?(enrollment.plan.renewal_plan_id)
    end

    def renew_waived_enrollment(waived_enrollment = nil)
      renewal_enrollment = @family.active_household.hbx_enrollments.new

      renewal_enrollment.coverage_kind = "health"
      renewal_enrollment.enrollment_kind = "open_enrollment"
      renewal_enrollment.kind = "employer_sponsored"

      benefit_group_assignment = @census_employee.renewal_benefit_group_assignment
      if benefit_group_assignment.blank?
        message = "Unable to find benefit_group_assignment for census_employee: \n"\
          "census_employee: #{@census_employee.full_name} "\
          "id: #{@census_employee.id} "

        Rails.logger.error { message }
        raise FamilyEnrollmentRenewalFactoryError, message
      end

      renewal_enrollment.benefit_group_assignment_id = benefit_group_assignment.id
      renewal_enrollment.benefit_group_id = benefit_group_assignment.benefit_group_id
      renewal_enrollment.effective_on = benefit_group_assignment.benefit_group.start_on
  
      renewal_enrollment.waiver_reason = waived_enrollment.try(:waiver_reason) || "I do not have other coverage"
      renewal_enrollment.renew_waived

      if renewal_enrollment.save
        return
      else
        message = "Unable to save waived renewal enrollment: #{renewal_enrollment.inspect}, \n" \
          "Error(s): \n #{renewal_enrollment.errors.map{|k,v| "#{k} = #{v}"}.join(" & \n")} \n"

          Rails.logger.error { message }

        raise FamilyEnrollmentRenewalFactoryError, message
      end
    end

    def renewal_builder(active_enrollment)
      renewal_enrollment = @family.active_household.hbx_enrollments.new
      renewal_enrollment = assign_common_attributes(active_enrollment, renewal_enrollment)
      renewal_enrollment.renew_enrollment
      renewal_enrollment
    end


    # def display_premiums(enrollment)
    #   puts "#{enrollment.aasm_state.humanize} enrollment amounts-------"
    #   puts enrollment.total_premium
    #   puts enrollment.total_employer_contribution
    #   puts enrollment.total_employee_cost
    #   puts "member premiums #{enrollment.hbx_enrollment_members.map(&:premium_amount)}"
    #   puts "---------------------------------"
    # end

    def save_renewal_enrollment(renewal_enrollment, active_enrollment)
      if renewal_enrollment.save
        renewal_enrollment
      else
        message = "Enrollment: #{active_enrollment.id}, \n" \
        "Unable to save renewal enrollment: #{renewal_enrollment.inspect}, \n" \
          "Error(s): \n #{renewal_enrollment.errors.map{|k,v| "#{k} = #{v}"}.join(" & \n")} \n"

        Rails.logger.error { message }
        raise FamilyEnrollmentRenewalFactoryError, message
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

    def clone_ivl_enrollment
      # consumer_role_id
      # elected_amount
      # elected_premium_credit
      # applied_premium_credit
      # elected_aptc_amount
      # applied_aptc_amount

      # renewal_enrollment.renew_coverage
    end

    def clone_shop_enrollment(active_enrollment, renewal_enrollment)
      # Find and associate with new ER benefit group

      benefit_group_assignment = @census_employee.renewal_benefit_group_assignment


      if benefit_group_assignment.blank?
        message = "Unable to find benefit_group_assignment for census_employee: \n"\
          "census_employee: #{@census_employee.full_name} "\
          "id: #{@census_employee.id} "\
          "for hbx_enrollment #{active_enrollment.id}"

        Rails.logger.error { message }
        raise FamilyEnrollmentRenewalFactoryError, message
      end

      renewal_enrollment.benefit_group_assignment_id = benefit_group_assignment.id
      renewal_enrollment.benefit_group_id = benefit_group_assignment.benefit_group_id

      renewal_enrollment.employee_role_id = active_enrollment.employee_role_id
      renewal_enrollment.effective_on = benefit_group_assignment.benefit_group.start_on
      # Set the HbxEnrollment to proper state

      # Renew waiver status
      if active_enrollment.is_coverage_waived? 
        renewal_enrollment.waiver_reason = active_enrollment.waiver_reason
        renewal_enrollment.waive_coverage 
      end

      renewal_enrollment.hbx_enrollment_members = clone_enrollment_members(active_enrollment)
      renewal_enrollment
    end
      
    def clone_enrollment_members(active_enrollment)
      hbx_enrollment_members = active_enrollment.hbx_enrollment_members
      hbx_enrollment_members.reject!{|hbx_enrollment_member| !hbx_enrollment_member.is_covered_on?(@plan_year_start_on - 1.day)  }
      hbx_enrollment_members.inject([]) do |members, hbx_enrollment_member|
        members << HbxEnrollmentMember.new({
          applicant_id: hbx_enrollment_member.applicant_id,
          eligibility_date: @plan_year_start_on,
          coverage_start_on: @plan_year_start_on,
          is_subscriber: hbx_enrollment_member.is_subscriber
        })
      end
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

  end
  
  class FamilyEnrollmentRenewalFactoryError < StandardError; end
end


