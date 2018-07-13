module Eligibility
  module EmployeeBenefitPackages
    # Deprecated
    def assign_default_benefit_package
      return true unless is_case_old?
      py = employer_profile.plan_years.published.first || employer_profile.plan_years.where(aasm_state: 'draft').first
      if py.present?
        if active_benefit_group_assignment.blank? || active_benefit_group_assignment.benefit_group.plan_year != py
          find_or_create_benefit_group_assignment(py.benefit_groups)
        end
      end

      if py = employer_profile.plan_years.renewing.first
        if benefit_group_assignments.where(:benefit_group_id.in => py.benefit_groups.map(&:id)).blank?
          add_renew_benefit_group_assignment(py.benefit_groups)
        end
      end
    end

    # Deprecated

    def find_or_create_benefit_group_assignment_deprecated(benefit_groups)
      bg_assignments = benefit_group_assignments.where(:benefit_group_id.in => benefit_groups.map(&:_id)).order_by(:'created_at'.desc)

      if bg_assignments.present?
        valid_bg_assignment = bg_assignments.where(:aasm_state.ne => 'initialized').first || bg_assignments.first
        valid_bg_assignment.make_active
      else
        add_benefit_group_assignment(benefit_groups.first, benefit_groups.first.plan_year.start_on)
      end
    end

    def find_or_create_benefit_group_assignment(benefit_packages)
      return find_or_create_benefit_group_assignment_deprecated(benefit_packages) if is_case_old?
      if benefit_packages.present?
        bg_assignments = benefit_group_assignments.where(:benefit_package_id.in => benefit_packages.map(&:_id)).order_by(:'created_at'.desc)

        if bg_assignments.present?
          valid_bg_assignment = bg_assignments.where(:aasm_state.ne => 'initialized').first || bg_assignments.first
          valid_bg_assignment.make_active
        else
          add_benefit_group_assignment(benefit_packages.first, benefit_packages.first.benefit_application.start_on)
        end
      end
    end

    # Deprecated
    # def add_default_benefit_group_assignment
    #   if plan_year = (self.employer_profile.plan_years.published_plan_years_by_date(hired_on).first || self.employer_profile.published_plan_year)
    #     add_benefit_group_assignment(plan_year.benefit_groups.first, plan_year.benefit_groups.first.start_on)
    #     if self.employer_profile.renewing_plan_year.present?
    #       add_renew_benefit_group_assignment(self.employer_profile.renewing_plan_year.benefit_groups.first)
    #     end
    #   end
    # end

    def add_renew_benefit_group_assignment(renewal_benefit_packages)
      return add_renew_benefit_group_assignment_deprecated(renewal_benefit_packages.first) if is_case_old?
      if renewal_benefit_packages.present?
        benefit_group_assignments.renewing.each do |benefit_group_assignment|
          if renewal_benefit_packages.map(&:id).include?(benefit_group_assignment.benefit_package.id)
            benefit_group_assignment.destroy
          end
        end

        bga = BenefitGroupAssignment.new(benefit_group: renewal_benefit_packages.first, start_on: renewal_benefit_packages.first.start_on, is_active: false)
        benefit_group_assignments << bga
      end
    end

    # Deprecated

    def add_renew_benefit_group_assignment_deprecated(new_benefit_group)
      raise ArgumentError, "expected BenefitGroup" unless new_benefit_group.is_a?(BenefitGroup)

      benefit_group_assignments.renewing.each do |benefit_group_assignment|
        if benefit_group_assignment.benefit_group_id == new_benefit_group.id
          benefit_group_assignment.destroy
        end
      end

      bga = BenefitGroupAssignment.new(benefit_group: new_benefit_group, start_on: new_benefit_group.start_on, is_active: false)
      benefit_group_assignments << bga
    end

    def add_benefit_group_assignment(new_benefit_group, start_on = nil)
      return add_benefit_group_assignment_deprecated(new_benefit_group) if is_case_old?
      raise ArgumentError, "expected BenefitGroup" unless new_benefit_group.is_a?(BenefitSponsors::BenefitPackages::BenefitPackage)
      reset_active_benefit_group_assignments(new_benefit_group)
      benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: new_benefit_group, start_on: (start_on || new_benefit_group.start_on))
    end

    # Deprecated

    def add_benefit_group_assignment_deprecated(new_benefit_group, start_on = nil)
      raise ArgumentError, "expected BenefitGroup" unless new_benefit_group.is_a?(BenefitGroup)
      reset_active_benefit_group_assignments(new_benefit_group)
      benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: new_benefit_group, start_on: (start_on || new_benefit_group.start_on))
    end

    def published_benefit_group_assignment
      benefit_group_assignments.detect do |benefit_group_assignment|
        benefit_group_assignment.benefit_group.plan_year.employees_are_matchable?
      end
    end

    def active_benefit_group
      active_benefit_group_assignment.benefit_group if active_benefit_group_assignment.present?
    end

    def published_benefit_group
      published_benefit_group_assignment.benefit_group if published_benefit_group_assignment
    end

    def renewal_published_benefit_group
      if renewal_benefit_group_assignment && renewal_benefit_group_assignment.benefit_group.plan_year.employees_are_matchable?
        renewal_benefit_group_assignment.benefit_group
      end
    end

    def possible_benefit_package
      if under_new_hire_enrollment_period?
        benefit_package = benefit_package_for_date(earliest_eligible_date)
        return benefit_package if benefit_package.present?
      end

      if renewal_benefit_group_assignment.present? && (renewal_benefit_group_assignment.benefit_application.is_renewal_enrolling? || renewal_benefit_group_assignment.benefit_application.enrollment_eligible?)
        renewal_benefit_group_assignment.benefit_package
      elsif active_benefit_group_assignment.present? && !active_benefit_group_assignment.benefit_package.is_conversion?
        active_benefit_group_assignment.benefit_package
      end
    end

    def reset_active_benefit_group_assignments(new_benefit_group)
      benefit_group_assignments.select { |assignment| assignment.is_active? }.each do |benefit_group_assignment|
        benefit_group_assignment.end_on = [new_benefit_group.start_on - 1.day, benefit_group_assignment.start_on].max
        benefit_group_assignment.update_attributes(is_active: false)
      end
    end

    #Deprecated
    def has_benefit_group_assignment_deprecated?
      (active_benefit_group_assignment.present? && (PlanYear::PUBLISHED).include?(active_benefit_group_assignment.benefit_group.plan_year.aasm_state)) ||
      (renewal_benefit_group_assignment.present? && (PlanYear::RENEWING_PUBLISHED_STATE).include?(renewal_benefit_group_assignment.benefit_group.plan_year.aasm_state))
    end

    def has_benefit_group_assignment?
      return has_benefit_group_assignment_deprecated? if is_case_old?
      (active_benefit_group_assignment.present? && (BenefitSponsors::BenefitApplications::BenefitApplication::PUBLISHED_STATES).include?(active_benefit_group_assignment.benefit_group.plan_year.aasm_state)) ||
      (renewal_benefit_group_assignment.present? && (PlanYear::RENEWING_PUBLISHED_STATE).include?(renewal_benefit_group_assignment.benefit_group.plan_year.aasm_state))
    end
  end
end
