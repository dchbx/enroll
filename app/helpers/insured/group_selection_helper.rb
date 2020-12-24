module Insured
  module GroupSelectionHelper

    def can_shop_individual?(person)
      person.present? && person.is_consumer_role_active?
    end

    def can_shop_shop?(person)
      person.present? && person.has_employer_benefits?
    end

    def can_shop_both_markets?(person)
      can_shop_individual?(person) && can_shop_shop?(person)
    end

    def can_shop_resident?(person)
      person.present? && person.is_resident_role_active?
    end

    def can_shop_individual_or_resident?(person)
      return true if (can_shop_individual?(person) && person.has_active_resident_member?)
      return true if (can_shop_resident?(person) && person.has_active_consumer_member?)
      return false
    end

    def health_relationship_benefits(benefit_group)
      return unless benefit_group.present?

      benefit_group.sole_source? ? composite_benefits(benefit_group) : traditional_benefits(benefit_group)
    end

    def composite_benefits(benefit_group)
      benefit_group.composite_tier_contributions.select(&:offered).map(&:composite_rating_tier)
    end

    def traditional_benefits(benefit_group)
      benefit_group.relationship_benefits.select(&:offered).map(&:relationship)
    end

    def dental_relationship_benefits(benefit_group)
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

    def view_market_places(person)
      markets = []
      markets += BenefitMarkets::Products::Product::MARKET_KINDS if can_shop_both_markets?(person)
      markets += BenefitMarkets::Products::Product::INDIVIDUAL_MARKET_KINDS if can_shop_individual_or_resident?(person)
      markets += ['shop'] if can_shop_shop?(person)
      markets += ['individual'] if can_shop_individual?(person)
      markets += ['coverall'] if can_shop_resident?(person)
      markets.uniq
    end

    def select_market(person, params)
      return params[:market_kind] if params[:market_kind].present?
      if params[:qle_id].present? && (!person.is_resident_role_active?)
        qle = QualifyingLifeEventKind.find(params[:qle_id])
        return qle.market_kind
      end
      if person.has_active_employee_role?
        'shop'
      elsif person.is_consumer_role_active?
        'individual'
      elsif person.is_resident_role_active?
        'coverall'
      else
        nil
      end
    end

    def get_benefit_group(benefit_group, employee_role, qle)
      if benefit_group.present? && (employee_role.employer_profile == benefit_group.employer_profile )
        benefit_group
      else
        select_benefit_group(qle, employee_role)
      end
    end

    def get_ivl_market_kind(person)
      if can_shop_individual?(person) || can_shop_individual_or_resident?(person)
        'individual'
      elsif can_shop_resident?(person)
        'coverall'
      end
    end

    def select_benefit_group(qle, employee_role)
      if (@market_kind == "shop" || @market_kind == "fehb") && employee_role.present?
        employee_role.benefit_group(qle: qle)
      else
        nil
      end
    end

    def insure_hbx_enrollment_for_shop_qle_flow
      @hbx_enrollment = selected_enrollment(@family, @employee_role, @coverage_kind) if (@market_kind == 'shop' || @market_kind == 'fehb') && (@change_plan == 'change_by_qle' || @enrollment_kind == 'sep') && @hbx_enrollment.blank?
    end

    def selected_enrollment(family, employee_role, coverage_kind)
      return unless employee_role.present?

      employer_profile = employee_role.employer_profile
      benefit_application = employer_profile.benefit_applications.detect { |ba| is_covered_plan_year?(ba, family.current_sep.effective_on)} || employer_profile.published_benefit_application
      enrollments = family.active_household&.hbx_enrollments
      if benefit_application.present? && benefit_application.is_renewing?
        renewal_enrollment(enrollments, employee_role, coverage_kind)
      else
        active_enrollment(family, enrollments, employee_role, coverage_kind)
      end
    end

    def renewal_enrollment(enrollments, employee_role, coverage_kind)
      enrollments.where(
        {
          :sponsored_benefit_package_id => employee_role.census_employee.renewal_published_benefit_package.try(:id),
          :aasm_state.in => HbxEnrollment::RENEWAL_STATUSES,
          :coverage_kind => coverage_kind
        }
      ).first
    end

    def active_enrollment(family, enrollments, employee_role, coverage_kind)
      coverage_date = family&.current_sep&.effective_on
      enrollments.where(
        {
          :sponsored_benefit_package_id => employee_role.census_employee.active_benefit_package(coverage_date).try(:id),
          :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES,
          :coverage_kind => coverage_kind
        }
      ).first
    end

    def benefit_group_assignment_by_plan_year(employee_role, benefit_group, change_plan, enrollment_kind)
      benefit_group.plan_year.is_renewing? ?
      employee_role.census_employee.renewal_benefit_group_assignment : (benefit_group.plan_year.aasm_state == "expired" && (change_plan == 'change_by_qle' or enrollment_kind == 'sep')) ? employee_role.census_employee.benefit_group_assignments.where(benefit_group_id: benefit_group.id).first : employee_role.census_employee.active_benefit_group_assignment
    end

    def is_market_kind_disabled?(kind, primary)
      unless can_shop_individual_or_resident?(primary)
        if @mc_market_kind.present?
          @mc_market_kind != kind
        else
          @disable_market_kind == kind
        end
      end
    end

    def is_market_kind_checked?(kind, primary)
      if @mc_market_kind.present?
        @mc_market_kind == kind
      elsif can_shop_individual_or_resident?(primary) && !(primary.has_active_employee_role?)
        kind == "individual"
      elsif primary.is_consumer_role_active? && !(primary.has_active_employee_role?)
        kind == "individual"
      elsif primary.is_resident_role_active? && !(primary.has_active_employee_role?)
        kind == "coverall"
      else
        @market_kind == kind
      end
    end

    def is_employer_disabled?(employee_role)
      if @mc_market_kind.present?
        return true if @mc_market_kind == "individual" || @mc_market_kind == "coverall"
        @hbx_enrollment.employee_role.blank? || @hbx_enrollment.employee_role.id != employee_role.id
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
        if change_plan == "change_plan" && enrollment.present? && enrollment.is_shop?
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

    def is_member_checked?(benefit_type, is_health_coverage, is_dental_coverage, is_ivl_coverage)
      if benefit_type.present? && benefit_type != "health"
        is_dental_coverage.nil? ? is_ivl_coverage : is_dental_coverage
      else
        is_health_coverage.nil? ? is_ivl_coverage : is_health_coverage
      end
    end

    def class_for_ineligible_row(family_member, is_ivl_coverage)

      class_names = @person.active_employee_roles.inject([]) do |class_names, employee_role|
        is_health_coverage, is_dental_coverage = shop_health_and_dental_attributes(family_member, employee_role)

        if !is_health_coverage && !is_health_coverage.nil?
          class_names << "ineligible_health_row_#{employee_role.id}"
        end

        if !is_dental_coverage && !is_dental_coverage.nil?
          class_names << "ineligible_dental_row_#{employee_role.id}"
        end
        class_names
      end

      class_names << "ineligible_ivl_row" if (!is_ivl_coverage.nil? && !is_ivl_coverage)
      class_names << "is_primary" if family_member.is_primary_applicant?

      class_names.to_sentence.gsub("and", '').gsub(",", "")
    end

    def shop_health_and_dental_attributes(family_member, employee_role)
      benefit_group = get_benefit_group(@benefit_group, employee_role, @qle)

      health_offered_relationship_benefits, dental_offered_relationship_benefits = shop_health_and_dental_relationship_benefits(employee_role, benefit_group)

      is_health_coverage = coverage_relationship_check(health_offered_relationship_benefits, family_member, @new_effective_on)
      is_health_coverage = @coverage_family_members_for_cobra.include?(family_member) if is_health_coverage && @coverage_family_members_for_cobra.present?
      if benefit_group.sole_source?
        is_health_coverage = composite_relationship_check(health_offered_relationship_benefits, family_member, @new_effective_on)
      else
        is_health_coverage = coverage_relationship_check(health_offered_relationship_benefits, family_member, @new_effective_on)
      end
      is_health_coverage = @coverage_family_members_for_cobra.include?(family_member) if is_health_coverage && @coverage_family_members_for_cobra.present?

      is_dental_coverage = coverage_relationship_check(dental_offered_relationship_benefits, family_member, @new_effective_on)
      is_dental_coverage = @coverage_family_members_for_cobra.include?(family_member) if is_dental_coverage && @coverage_family_members_for_cobra.present?

      return is_health_coverage, is_dental_coverage
    end

    def shop_health_and_dental_relationship_benefits(employee_role, benefit_group)

      health_offered_relationship_benefits = health_relationship_benefits(benefit_group)

      if is_eligible_for_dental?(employee_role, @change_plan, @hbx_enrollment)
        dental_offered_relationship_benefits = dental_relationship_benefits(benefit_group)
      end

      return health_offered_relationship_benefits, dental_offered_relationship_benefits
    end
  end
end
