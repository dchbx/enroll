module EnrollmentShopping
	class EnrollmentBuilder
		def initialize(c_household, e_role, c_kind)
			@coverage_household = c_household
			@household = @coverage_household.household
			@employee_role = e_role
      @coverage_kind = c_kind
		end

    def build_change_waiver_enrollment(previous_enrollment:, is_qle: false, optional_effective_on: nil, waiver_reason: nil)
			enrollment = build_common_enrollment_information("employer_sponsored")
      enrollment.predecessor_enrollment_id = previous_enrollment.id
      enrollment.waiver_reason = waiver_reason

			if is_qle && enrollment.family.is_under_special_enrollment_period?
				if optional_effective_on.present?
					enrollment.effective_on = optional_effective_on
				else
          possible_benefit_package = benefit_package_for_date(@employee_role, enrollment.family.current_sep.effective_on)
          if possible_benefit_package
            # They are in a sep and there is an applicable benefit package
            benefit_package = possible_benefit_package
            enrollment.effective_on = enrollment.family.current_sep.effective_on
          else
            # They are in a sep, but there is NO benefit package available then
            # Maybe they weren't hired yet
            effective_date = earliest_eligible_date_for_shop(@employee_role)
            enrollment.effective_on = effective_date
            benefit_package = benefit_package_for_date(@employee_role, effective_date)
          end
        end
				enrollment.enrollment_kind = "special_enrollment"
        enrollment.special_enrollment_period_id = enrollment.family.current_sep.id
        # TODO: Assign sep
			else
				effective_date = earliest_eligible_date_for_shop(@employee_role)
				enrollment.effective_on = effective_date
				enrollment.enrollment_kind = "open_enrollment"
			end

			enrollment.rebuild_members_by_coverage_household(coverage_household: @coverage_household)

			enrollment.hbx_enrollment_members = enrollment.hbx_enrollment_members.select do |member|
				member.is_subscriber?
			end

      benefit_package ||= previous_enrollment.sponsored_benefit_package
      sponsored_benefit = benefit_package.sponsored_benefit_for(@coverage_kind)
			set_benefit_information(enrollment, sponsored_benefit, benefit_package)

      copy_member_coverage_dates(previous_enrollment, enrollment)
      enrollment
    end

    def build_new_waiver_enrollment(is_qle: false, optional_effective_on: nil, waiver_reason: nil)
			enrollment = build_common_enrollment_information("employer_sponsored")
      enrollment.waiver_reason = waiver_reason
			benefit_package = nil

			if is_qle && enrollment.family.is_under_special_enrollment_period?
				if optional_effective_on.present?
					benefit_package = benefit_package_for_date(@employee_role, optional_effective_on)
					enrollment.effective_on = optional_effective_on
				else
					possible_benefit_package = benefit_package_for_date(@employee_role, enrollment.family.current_sep.effective_on)
					if possible_benefit_package
						# They are in a sep and there is an applicable benefit package
						benefit_package = possible_benefit_package
						enrollment.effective_on = enrollment.family.current_sep.effective_on
					else
						# They are in a sep, but there is NO benefit package available then
						# Maybe they weren't hired yet
						effective_date = earliest_eligible_date_for_shop(@employee_role)
						enrollment.effective_on = effective_date
						benefit_package = benefit_package_for_date(@employee_role, effective_date)
					end
				end
				enrollment.enrollment_kind = "special_enrollment"
        enrollment.special_enrollment_period_id = enrollment.family.current_sep.id
				# TODO: Assign sep
			else
				effective_date = earliest_eligible_date_for_shop(@employee_role)
				enrollment.effective_on = effective_date
				enrollment.enrollment_kind = "open_enrollment"
				benefit_package = benefit_package_for_date(@employee_role, effective_date)
			end

			enrollment.rebuild_members_by_coverage_household(coverage_household: @coverage_household)

			enrollment.hbx_enrollment_members = enrollment.hbx_enrollment_members.select do |member|
				member.is_subscriber?
			end

			sponsored_benefit = benefit_package.sponsored_benefit_for(@coverage_kind)
			set_benefit_information(enrollment, sponsored_benefit, benefit_package)

      check_for_affected_enrollment(enrollment, sponsored_benefit)

			enrollment
    end

		def build_new_enrollment(family_member_ids: [], is_qle: false, optional_effective_on: nil)
			enrollment = build_common_enrollment_information("employer_sponsored")
			benefit_package = nil

			if is_qle && enrollment.family.is_under_special_enrollment_period?
				if optional_effective_on.present?
					benefit_package = benefit_package_for_date(@employee_role, optional_effective_on)
					enrollment.effective_on = optional_effective_on
				else
					possible_benefit_package = benefit_package_for_date(@employee_role, enrollment.family.current_sep.effective_on)
					if possible_benefit_package
						# They are in a sep and there is an applicable benefit package
						benefit_package = possible_benefit_package
						enrollment.effective_on = enrollment.family.current_sep.effective_on
					else
						# They are in a sep, but there is NO benefit package available then
						# Maybe they weren't hired yet
						effective_date = earliest_eligible_date_for_shop(@employee_role)
						enrollment.effective_on = effective_date
						benefit_package = benefit_package_for_date(@employee_role, effective_date)
					end
				end
				enrollment.enrollment_kind = "special_enrollment"
        enrollment.special_enrollment_period_id = enrollment.family.current_sep.id
				# TODO: Assign sep
			else
				effective_date = earliest_eligible_date_for_shop(@employee_role)
				enrollment.effective_on = effective_date
				enrollment.enrollment_kind = "open_enrollment"
				benefit_package = benefit_package_for_date(@employee_role, effective_date)
			end

			build_enrollment_members(enrollment, family_member_ids)

			sponsored_benefit = benefit_package.sponsored_benefit_for(@coverage_kind)
			set_benefit_information(enrollment, sponsored_benefit, benefit_package)

      check_for_affected_enrollment(enrollment, sponsored_benefit)

			enrollment
		end

		def build_change_enrollment(previous_enrollment:, is_qle: false, optional_effective_on: nil, family_member_ids: [])
			enrollment = build_common_enrollment_information("employer_sponsored")
      enrollment.predecessor_enrollment_id = previous_enrollment.id

			if is_qle && enrollment.family.is_under_special_enrollment_period?
				if optional_effective_on.present?
					enrollment.effective_on = optional_effective_on
				else
          possible_benefit_package = benefit_package_for_date(@employee_role, enrollment.family.current_sep.effective_on)
          if possible_benefit_package
            # They are in a sep and there is an applicable benefit package
            benefit_package = possible_benefit_package
            enrollment.effective_on = enrollment.family.current_sep.effective_on
          else
            # They are in a sep, but there is NO benefit package available then
            # Maybe they weren't hired yet
            effective_date = earliest_eligible_date_for_shop(@employee_role)
            enrollment.effective_on = effective_date
            benefit_package = benefit_package_for_date(@employee_role, effective_date)
          end
        end
				enrollment.enrollment_kind = "special_enrollment"
        enrollment.special_enrollment_period_id = enrollment.family.current_sep.id
        # TODO: Assign sep        
      else
				enrollment.effective_on = previous_enrollment.effective_on
				enrollment.enrollment_kind = "open_enrollment"
			end

			build_enrollment_members(enrollment, family_member_ids)

			benefit_package ||= previous_enrollment.sponsored_benefit_package
			sponsored_benefit = benefit_package.sponsored_benefit_for(@coverage_kind)
			set_benefit_information(enrollment, sponsored_benefit, benefit_package)
      copy_member_coverage_dates(previous_enrollment, enrollment)
      enrollment
		end
		
		def build_common_enrollment_information(enrollment_kind)
			enrollment = @household.hbx_enrollments.build
			enrollment.coverage_household_id = @coverage_household.id
			enrollment.kind = enrollment_kind
			enrollment.employee_role = @employee_role
			enrollment
		end

		def set_benefit_information(enrollment, sponsored_benefit, benefit_package)
      enrollment.sponsored_benefit_package_id = benefit_package.id
      enrollment.sponsored_benefit_id = sponsored_benefit.id
      enrollment.rating_area_id = benefit_package.recorded_rating_area.id
      enrollment.benefit_sponsorship_id = benefit_package.benefit_sponsorship.id
		end

		def build_enrollment_members(enrollment, family_member_ids)
			enrollment.rebuild_members_by_coverage_household(coverage_household: @coverage_household)

			enrollment.hbx_enrollment_members = enrollment.hbx_enrollment_members.select do |member|
				family_member_ids.include? member.applicant_id
			end
		end

    def check_for_affected_enrollment(enrollment, sponsored_benefit)
      aef = AffectedEnrollmentFinder.new
      affected_enrollments = aef.for_sponsored_benefit_and_date(enrollment, sponsored_benefit, enrollment.effective_on)
      if affected_enrollments.any?
        affected_enrollment = affected_enrollments.first
        enrollment.predecessor_enrollment_id = affected_enrollment.id
        copy_member_coverage_dates(affected_enrollment, enrollment)
      end
    end

    def copy_member_coverage_dates(old_hem, new_hem)
      old_hem.hbx_enrollment_members.each do |old_member|
        new_hem.hbx_enrollment_members.each do |new_member|
          if old_member.applicant_id == new_member.applicant_id
            new_member.coverage_start_on = old_member.coverage_start_on
          end
        end
      end
    end

    def benefit_package_for_date(employee_role, start_date)
      employee_role.benefit_package_for_date(start_date)
    end

    def earliest_eligible_date_for_shop(employee_role)
      employee_role.census_employee.coverage_effective_on
    end
  end
end
