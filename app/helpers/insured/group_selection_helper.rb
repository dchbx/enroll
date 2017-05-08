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

    def insure_hbx_enrollment_for_shop_qle_flow
      if @market_kind == 'shop' && (@change_plan == 'change_by_qle' || @enrollment_kind == 'sep')
        if @hbx_enrollment.blank? # && @employee_role.present?
          # plan_year = @employee_role.employer_profile.find_plan_year_by_effective_date(@new_effective_on)
          # id_list = plan_year.benefit_groups.collect(&:_id).uniq
          # enrollments = @family.active_household.hbx_enrollments.shop_market.enrolled_and_renewing.where(:"benefit_group_id".in => id_list).effective_desc
          # @hbx_enrollment = enrollments.first

          @hbx_enrollment = @family.active_household.hbx_enrollments.shop_market.enrolled_and_renewing.effective_desc.detect { |hbx| hbx.may_terminate_coverage? }
        end
      end
    end

    def select_market(person, params)
      return params[:market_kind] if params[:market_kind].present?
      if @person.try(:has_active_employee_role?)
        'shop'
      elsif @person.try(:has_active_consumer_role?)
        'individual'
      else
        nil
      end
    end

    def self.selected_enrollment(family, employee_role)
      py = employee_role.employer_profile.plan_years.detect { |py| (py.start_on.beginning_of_day..py.end_on.end_of_day).cover?(family.current_sep.effective_on)}
      id_list = py.benefit_groups.map(&:id) if py.present?
      enrollments = family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list, :aasm_state.ne => 'shopping')
      renewal_enrollment = enrollments.detect { |enr| enr.may_terminate_coverage? && enr.benefit_group_id == employee_role.census_employee.renewal_published_benefit_group.try(:id) && (HbxEnrollment::RENEWAL_STATUSES).include?(enr.aasm_state)}
      active_enrollment = enrollments.detect { |enr| enr.may_terminate_coverage? && enr.benefit_group_id == employee_role.census_employee.active_benefit_group.try(:id) && (HbxEnrollment::ENROLLED_STATUSES).include?(enr.aasm_state)}
      if py.present? && py.is_renewing?
        return renewal_enrollment
      else
        return active_enrollment
      end
    end

    def coverage_tr_class(is_coverage, is_ineligible_for_individual)
      tr_class = ""
      tr_class += " ineligible_row" unless is_coverage
      tr_class += " ineligible_row_for_ivl" if is_ineligible_for_individual
    end

    def coverage_td_class(is_ineligible_for_individual)
      td_class = ""
      td_class += " ineligible_detail_for_ivl" if is_ineligible_for_individual
    end

    def check_for_coverage(family_member, index)
      if @market_kind == 'individual' || can_shop_both_markets?(@person)
        role = family_member.person.consumer_role
        family = family_member.family
        rule = InsuredEligibleForBenefitRule.new(role, @benefit, {family: family, coverage_kind: @coverage_kind, new_effective_on: @new_effective_on})
        is_coverage, errors = rule.satisfied?
        @show_residency_alert = !rule.is_residency_status_satisfied? if @show_residency_alert == false
        errors = [incarceration_cannot_purchase(family_member)] if index==0 && errors && errors.flatten.detect{|err| err.match(/incarceration/)}
        [is_coverage, errors]
      end
    end

    def ineligible_due_to_non_dc_address(family_member)
      return nil if family_member.blank?
      person = family_member.primary_applicant
      is_ineligible_for_individual = person.try(:has_active_consumer_role?) && person.try(:has_active_employee_role?) &&
                                      person.no_dc_address.present?
    end
  end
end
