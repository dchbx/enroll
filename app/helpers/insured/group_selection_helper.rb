module Insured
  module GroupSelectionHelper
    def can_shop_individual?(person)
      person.try(:has_active_consumer_role?)
    end

    def can_shop_shop?(person)
      person.present? && person.has_employer_benefits?
    end

    def can_shop_both_markets?(person)
      can_shop_individual?(person) && can_shop_shop?(person)
    end

    def can_shop_resident?(person)
      person.try(:has_active_resident_role?)
    end

    def health_relationship_benefits(employee_role)
      benefit_group = employee_role.census_employee.renewal_published_benefit_group || employee_role.census_employee.active_benefit_group
      if benefit_group.present?
        benefit_group.relationship_benefits.select(&:offered).map(&:relationship)
      end
    end

    def dental_relationship_benefits(employee_role)
      benefit_group = employee_role.census_employee.renewal_published_benefit_group || employee_role.census_employee.active_benefit_group
      if benefit_group.present?
        benefit_group.dental_relationship_benefits.select(&:offered).map(&:relationship)
      end
    end

    def calculate_effective_on(market_kind:, employee_role:, benefit_group:)
      HbxEnrollment.calculate_effective_on_from(
        market_kind: market_kind,
        qle: (@change_plan == 'change_by_qle' or @enrollment_kind == 'sep'),
        family: @family,
        employee_role: employee_role,
        benefit_group: benefit_group,
        benefit_sponsorship: HbxProfile.current_hbx.try(:benefit_sponsorship))
    end

    def select_market(person, params)
      return params[:market_kind] if params[:market_kind].present?
      if params[:qle_id].present? && (!person.has_active_resident_role?)
        qle = QualifyingLifeEventKind.find(params[:qle_id])
        return qle.market_kind
      end
      if person.has_active_employee_role?
        'shop'
      elsif person.has_active_consumer_role? && !person.has_active_resident_role?
        'individual'
      elsif person.has_active_resident_role?
        'coverall'
      else
        nil
      end
    end

    def select_benefit_group(qle)
      if @market_kind == "shop"
        @employee_role.present? ? @employee_role.benefit_group(qle: qle) : nil
      else
        nil
      end
    end

    def insure_hbx_enrollment_for_shop_qle_flow
      if @market_kind == 'shop' && (@change_plan == 'change_by_qle' || @enrollment_kind == 'sep') && @hbx_enrollment.blank?
        @hbx_enrollment = selected_enrollment(@family, @employee_role)
      end
    end

    def selected_enrollment(family, employee_role)
      employer_profile = employee_role.employer_profile
      py = employer_profile.plan_years.detect { |py| is_covered_plan_year?(py, family.current_sep.effective_on)} || employer_profile.published_plan_year
      enrollments = family.active_household.hbx_enrollments
      if py.present? && py.is_renewing?
        renewal_enrollment(enrollments, employee_role)
      else
        active_enrollment(enrollments, employee_role)
      end
    end

    def renewal_enrollment(enrollments, employee_role)
      enrollments.where({
        :"benefit_group_id" => employee_role.census_employee.renewal_published_benefit_group.try(:id),
        :"aasm_state".in => HbxEnrollment::RENEWAL_STATUSES
        }).first
    end

    def active_enrollment(enrollments, employee_role)
      enrollments.where({
        :"benefit_group_id" => employee_role.census_employee.active_benefit_group.try(:id),
        :"aasm_state".in => HbxEnrollment::ENROLLED_STATUSES
        }).first
    end

    def benefit_group_assignment_by_plan_year(employee_role, benefit_group, change_plan, enrollment_kind)
      benefit_group.plan_year.is_renewing? ?
      employee_role.census_employee.renewal_benefit_group_assignment : (benefit_group.plan_year.aasm_state == "expired" && (change_plan == 'change_by_qle' or enrollment_kind == 'sep')) ? employee_role.census_employee.benefit_group_assignments.where(benefit_group_id: benefit_group.id).first : employee_role.census_employee.active_benefit_group_assignment
    end

    def is_market_kind_disabled?(kind)
      if @mc_market_kind.present?
        @mc_market_kind != kind
      else
        @disable_market_kind == kind
      end
    end

    def is_market_kind_checked?(kind)
      if @mc_market_kind.present?
        @mc_market_kind == kind
      else
        @market_kind == kind
      end
    end

    def is_employer_disabled?(employee_role)
      if @mc_market_kind.present?
        @mc_market_kind == "individual" || @hbx_enrollment.employee_role.id != employee_role.id
      else
        false
      end
    end

    def is_employer_checked?(employee_role)
      if @mc_market_kind.present?
        !(is_employer_disabled?(employee_role))
      else
        employee_role.id == @employee_role.id
      end
    end

    def is_coverage_kind_checked?(coverage_kind)
      if @mc_coverage_kind.present?
        @mc_coverage_kind == coverage_kind
      else
        coverage_kind == "health" ? true : false
      end
    end

    def is_coverage_kind_disabled?(coverage_kind)
      if @mc_coverage_kind.present?
        @mc_coverage_kind != coverage_kind
      else
        false
      end
    end

    def is_eligible_for_dental?(employee_role, change_plan, enrollment)
      renewing_bg = employee_role.census_employee.renewal_published_benefit_group
      active_bg = employee_role.census_employee.active_benefit_group

      if change_plan != "change_by_qle"
        if change_plan == "change_plan" && enrollment.present?
          enrollment.benefit_group.is_offering_dental?
        elsif employee_role.can_enroll_as_new_hire?
          active_bg.present? && active_bg.is_offering_dental?
        else
          ( renewing_bg || active_bg ).present? && (renewing_bg || active_bg ).is_offering_dental?
        end
      else
        effective_on = employee_role.person.primary_family.current_sep.effective_on

        if renewing_bg.present? && is_covered_plan_year?(renewing_bg.plan_year, effective_on)
          renewing_bg.is_offering_dental?
        elsif active_bg.present?
          active_bg.is_offering_dental?
        end
      end
    end

    def is_covered_plan_year?(plan_year, effective_on)
      (plan_year.start_on.beginning_of_day..plan_year.end_on.end_of_day).cover? effective_on
    end
  end
end
