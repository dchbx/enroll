module Eligibility
  module EmployeeBenefitPackages
    # Deprecated
    def assign_default_benefit_package
      return true unless is_case_old?

      py = employer_profile.plan_years.published.first || employer_profile.plan_years.where(aasm_state: 'draft').first

      create_benefit_group_assignment(py.benefit_groups) if py.present? && active_benefit_group_assignment.blank? || active_benefit_group_assignment&.benefit_group&.plan_year != py

      if py = employer_profile.plan_years.renewing.first
        if benefit_group_assignments.where(:benefit_group_id.in => py.benefit_groups.map(&:id)).blank?
          add_renew_benefit_group_assignment(py.benefit_groups)
        end
      end
    end

    # R4 Updates
    # When switching benefit package, we are always creating a new BGA and terminating/cancelling previous BGA
    # TODO: Creating BGA for first benefit group only

    def create_benefit_group_assignment(benefit_packages, off_cycle: false)
      assignment = off_cycle ? off_cycle_benefit_group_assignment : active_benefit_group_assignment
      if benefit_packages.present?
        if assignment.present?
          end_date, new_start_on =
            if assignment.start_on >= TimeKeeper.date_of_record
              [assignment.start_on, benefit_packages.first.start_on]
            else
              [TimeKeeper.date_of_record.prev_day, TimeKeeper.date_of_record]
            end
          verified_end_date = verified_end_date_for_benefit_group_assignment(end_date, assignment)
          assignment.end_benefit(verified_end_date)
        end
        deactive_benefit_group_assignments(benefit_packages.first)
        add_benefit_group_assignment(benefit_packages.first, new_start_on || benefit_packages.first.start_on, benefit_packages.first.end_on)
      end
    end

    def deactive_benefit_group_assignments(benefit_package)
      benefit_group_assignments.by_benefit_package(benefit_package).each do |benefit_group_assignment|
        benefit_group_assignment.update_attributes(is_active: false) if benefit_group_assignment.is_active == true
      end
    end

    def verified_end_date_for_benefit_group_assignment(end_date, assignment)
      if assignment.benefit_package.effective_period.cover?(end_date)
        end_date
      elsif assignment.start_on >= TimeKeeper.date_of_record
        assignment.benefit_package.effective_period.min
      else
        assignment.benefit_package.effective_period.max
      end
    end

    def add_renew_benefit_group_assignment(renewal_benefit_packages)
      if renewal_benefit_packages.present?
        if renewal_benefit_group_assignment.present?
          end_date, new_start_on =
            if renewal_benefit_group_assignment.start_on >= TimeKeeper.date_of_record
              [renewal_benefit_group_assignment.start_on, renewal_benefit_packages.first.start_on]
            else
              [TimeKeeper.date_of_record.prev_day, TimeKeeper.date_of_record]
            end
          verified_end_date = verified_end_date_for_benefit_group_assignment(end_date, renewal_benefit_group_assignment)
          renewal_benefit_group_assignment.end_benefit(verified_end_date)
        end
        deactive_benefit_group_assignments(renewal_benefit_packages.first)
        add_benefit_group_assignment(renewal_benefit_packages.first, new_start_on || renewal_benefit_packages.first.start_on, renewal_benefit_packages.first.end_on)
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

      bga = BenefitGroupAssignment.new(benefit_group: new_benefit_group, start_on: new_benefit_group.start_on)
      benefit_group_assignments << bga
    end

    def add_benefit_group_assignment(new_benefit_group, start_on = nil, end_on = nil)
      return add_benefit_group_assignment_deprecated(new_benefit_group) if is_case_old?
      raise ArgumentError, "expected BenefitGroup" unless new_benefit_group.is_a?(BenefitSponsors::BenefitPackages::BenefitPackage)
      # reset_active_benefit_group_assignments(new_benefit_group)
      benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: new_benefit_group, start_on: (start_on || new_benefit_group.start_on), end_on: end_on || new_benefit_group.end_on)
    end

    # Deprecated

    def add_benefit_group_assignment_deprecated(new_benefit_group, start_on = nil)
      raise ArgumentError, "expected BenefitGroup" unless new_benefit_group.is_a?(BenefitGroup)
      reset_active_benefit_group_assignments(new_benefit_group)
      benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: new_benefit_group, start_on: (start_on || new_benefit_group.start_on))
    end

    def published_benefit_group_assignment
      benefit_group_assignments.detect do |benefit_group_assignment|
        benefit_group_assignment.benefit_group.plan_year.is_submitted?
      end
    end

    def active_benefit_group
      active_benefit_group_assignment.benefit_group if active_benefit_group_assignment.present?
    end

    def published_benefit_group
      published_benefit_group_assignment.benefit_group if published_benefit_group_assignment
    end

    def renewal_published_benefit_group
      if renewal_benefit_group_assignment && renewal_benefit_group_assignment.benefit_group.plan_year.is_submitted?
        renewal_benefit_group_assignment.benefit_group
      end
    end

    def off_cycle_published_benefit_group
      off_cycle_benefit_group_assignment.benefit_package if off_cycle_benefit_group_assignment&.benefit_package&.benefit_application&.is_submitted?
    end

    def possible_benefit_package(shop_under_current: false, shop_under_future: false)
      if under_new_hire_enrollment_period?
        return active_benefit_group_assignment.benefit_package if shop_under_current && active_benefit_group_assignment.present? && !active_benefit_group_assignment.benefit_package.is_conversion?
        return benefit_package_based_on_assignment if shop_under_future

        benefit_package = benefit_package_for_date(earliest_eligible_date)
        return benefit_package if benefit_package.present?
      end

      benefit_package_based_on_assignment
    end

    def benefit_package_based_on_assignment
      if renewal_benefit_group_assignment.present? && (renewal_benefit_group_assignment.benefit_application.is_renewal_enrolling? || renewal_benefit_group_assignment.benefit_application.enrollment_eligible?)
        renewal_benefit_group_assignment.benefit_package
      elsif off_cycle_benefit_group_assignment.present? && (off_cycle_benefit_group_assignment.benefit_application.is_enrolling? || off_cycle_benefit_group_assignment.benefit_application.enrollment_eligible?)
        off_cycle_benefit_group_assignment.benefit_package
      elsif active_benefit_group_assignment.present? && !active_benefit_group_assignment.benefit_package.is_conversion?
        active_benefit_group_assignment.benefit_package
      end
    end

    def reset_active_benefit_group_assignments(new_benefit_group)
      benefit_group_assignments.select { |assignment| assignment.start_on <= TimeKeeper.date_of_record }.each do |benefit_group_assignment|
        end_on = benefit_group_assignment.end_on || (new_benefit_group.start_on - 1.day)
        if is_case_old?
          end_on = benefit_group_assignment.plan_year.end_on unless benefit_group_assignment.plan_year.coverage_period_contains?(end_on)
        else
          end_on = benefit_group_assignment.benefit_application.end_on unless benefit_group_assignment.benefit_application.effective_period.cover?(end_on)
        end
        benefit_group_assignment.update_attributes(end_on: end_on)
      end
    end

    #Deprecated
    def has_benefit_group_assignment_deprecated?
      (active_benefit_group_assignment.present? && (PlanYear::PUBLISHED).include?(active_benefit_group_assignment.benefit_group.plan_year.aasm_state)) ||
      (renewal_benefit_group_assignment.present? && (PlanYear::RENEWING_PUBLISHED_STATE).include?(renewal_benefit_group_assignment.benefit_group.plan_year.aasm_state))
    end

    def has_benefit_group_assignment?
      return has_benefit_group_assignment_deprecated? if is_case_old?
      (active_benefit_group_assignment.present? && (BenefitSponsors::BenefitApplications::BenefitApplication::PUBLISHED_STATES + BenefitSponsors::BenefitApplications::BenefitApplication::IMPORTED_STATES).include?(active_benefit_group_assignment.benefit_application.aasm_state)) ||
      (renewal_benefit_group_assignment.present? && renewal_benefit_group_assignment.benefit_application.is_renewing?)
    end
  end
end
