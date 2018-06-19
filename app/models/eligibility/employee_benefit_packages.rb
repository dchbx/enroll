module Eligibility
  module EmployeeBenefitPackages

    def assign_default_benefit_package
      py = employer_profile.plan_years.published.first || employer_profile.plan_years.where(aasm_state: 'draft').first
      if py.present?
        if active_benefit_group_assignment.blank? || active_benefit_group_assignment.benefit_group.plan_year != py
          find_or_create_benefit_group_assignment(py.benefit_groups)
        end
      end

      if py = employer_profile.plan_years.renewing.first
        if benefit_group_assignments.where(:benefit_group_id.in => py.benefit_groups.map(&:id)).blank?
          add_renew_benefit_group_assignment(py.benefit_groups.first)
        end
      end
    end

    def find_or_create_benefit_group_assignment(benefit_groups)
      bg_assignments = benefit_group_assignments.where(:benefit_group_id.in => benefit_groups.map(&:_id)).order_by(:'created_at'.desc)

      if bg_assignments.present?
        valid_bg_assignment = bg_assignments.where(:aasm_state.ne => 'initialized').first || bg_assignments.first
        valid_bg_assignment.make_active
      else
        add_benefit_group_assignment(benefit_groups.first, benefit_groups.first.plan_year.start_on)
      end
    end

    def add_default_benefit_group_assignment
      if plan_year = (self.employer_profile.plan_years.published_plan_years_by_date(hired_on).first || self.employer_profile.published_plan_year)
        add_benefit_group_assignment(plan_year.benefit_groups.first, plan_year.benefit_groups.first.start_on)
        if self.employer_profile.renewing_plan_year.present?
          add_renew_benefit_group_assignment(self.employer_profile.renewing_plan_year.benefit_groups.first)
        end
      end
    end

    def add_renew_benefit_group_assignment(new_benefit_group)
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
      raise ArgumentError, "expected BenefitGroup" unless new_benefit_group.is_a?(BenefitGroup)
      reset_active_benefit_group_assignments(new_benefit_group)
      benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: new_benefit_group, start_on: (start_on || new_benefit_group.start_on))
    end

    def active_benefit_group_assignment
      benefit_group_assignments.detect { |assignment| assignment.is_active? }
    end

    def renewal_benefit_group_assignment
      benefit_group_assignments.order_by(:'updated_at'.desc).detect{ |assignment| assignment.plan_year && assignment.plan_year.is_renewing? }
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

    def reset_active_benefit_group_assignments(new_benefit_group)
      benefit_group_assignments.select { |assignment| assignment.is_active? }.each do |benefit_group_assignment|
        benefit_group_assignment.end_on = [new_benefit_group.start_on - 1.day, benefit_group_assignment.start_on].max
        benefit_group_assignment.update_attributes(is_active: false)
      end
    end

    def has_benefit_group_assignment?
      (active_benefit_group_assignment.present? && (PlanYear::PUBLISHED).include?(active_benefit_group_assignment.benefit_group.plan_year.aasm_state)) ||
      (renewal_benefit_group_assignment.present? && (PlanYear::RENEWING_PUBLISHED_STATE).include?(renewal_benefit_group_assignment.benefit_group.plan_year.aasm_state))
    end
  end
end
