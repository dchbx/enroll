# frozen_string_literal: true

module Employers
  module EmployerHelper
    def address_kind
      @family.try(:census_employee).try(:address).try(:kind) || 'home'
    end

    def employee_state_format(census_employee = nil, employee_state = nil, termination_date = nil)
      if employee_state == "employee_termination_pending" && termination_date.present?
        "Termination Pending #{termination_date}"
      elsif employee_state == 'employee_role_linked'
        'Account Linked'
      elsif employee_state == 'eligible'
        'No Account Linked'
      elsif employee_state == "cobra_linked" &&
            (
              census_employee.has_cobra_hbx_enrollment? ||
              census_employee.active_benefit_group_enrollments.present? && census_employee.cobra_begin_date.present?
            )
        "Cobra Enrolled"
      else
        employee_state.humanize
      end
    end

    def simple_enrollment_state(census_employee = nil)
      hbx = census_employee.active_benefit_group_enrollments.try(:first)
      hbx.present? ? "#{hbx.coverage_kind.titleize} - #{hbx.aasm_state.titleize}" : ""
    end

    def enrollment_state(census_employee = nil)
      humanize_enrollment_states(census_employee.active_benefit_group_assignment).gsub("Coverage Selected", "Enrolled").gsub("Coverage Waived", "Waived").gsub("Coverage Terminated", "Terminated").gsub("Coverage Termination Pending",
                                                                                                                                                                                                         "Coverage Termination Pending").html_safe
    end

    def renewal_enrollment_state(census_employee = nil)
      humanize_enrollment_states(census_employee.renewal_benefit_group_assignment).gsub("Coverage Renewing", "Auto-Renewing").gsub("Coverage Selected", "Enrolling").gsub("Coverage Waived", "Waiving").gsub("Coverage Terminated",
                                                                                                                                                                                                             "Terminating").html_safe
    end

    def off_cycle_enrollment_state(census_employee = nil)
      humanize_enrollment_states(census_employee.off_cycle_benefit_group_assignment).gsub("Coverage Selected", "Enrolled")
                                                                                    .gsub("Coverage Waived", "Waived").gsub("Coverage Terminated", "Terminated")
                                                                                    .gsub("Coverage Termination Pending", "Coverage Termination Pending")
                                                                                    .html_safe
    end

    def reinstated_enrollment_state(census_employee = nil)
      humanize_enrollment_states(census_employee.future_active_reinstated_benefit_group_assignment)
        .gsub("Coverage Selected", "Enrolled")
        .gsub("Coverage Waived", "Waived").gsub("Coverage Terminated", "Terminated")
        .gsub("Coverage Termination Pending", "Coverage Termination Pending")
        .html_safe
    end

    def humanize_enrollment_states(benefit_group_assignment)
      enrollment_states = []

      if benefit_group_assignment
        enrollments = benefit_group_assignment.hbx_enrollments
        %w[health dental].each do |coverage_kind|
          enrollment = enrollments.select{ |enr| enr.coverage_kind == coverage_kind}.max_by(&:created_at)
          next unless enrollment

          enrollment_states << "#{employee_benefit_group_assignment_status(benefit_group_assignment.census_employee, enrollment.aasm_state)} (#{coverage_kind})"
        end
        enrollment_states << '' if enrollment_states.compact.empty?
      end

      enrollment_states.compact.join('<br/> ').titleize.to_s.html_safe
    end

    def benefit_group_assignment_status(enrollment_status)
      assignment_mapping = {
        'coverage_renewing' => HbxEnrollment::RENEWAL_STATUSES,
        'coverage_terminated' => HbxEnrollment::TERMINATED_STATUSES,
        'coverage_termination_pending' => ["coverage_termination_pending"],
        'coverage_selected' => HbxEnrollment::ENROLLED_STATUSES - ["coverage_termination_pending"],
        'coverage_waived' => HbxEnrollment::WAIVED_STATUSES
      }
      assignment_mapping.each do |bgsm_state, enrollment_statuses|
        return bgsm_state if enrollment_statuses.include?(enrollment_status.to_s)
      end
    end

    def employee_benefit_group_assignment_status(census_employee, enrollment_status)
      state = benefit_group_assignment_status(enrollment_status)
      if census_employee.is_cobra_status?
        case state
        when 'coverage_waived'
          'cobra_waived'
        when 'coverage_renewing'
          'cobra_renewed'
        else
          state
        end
      else
        state
      end
    end

    def invoice_formated_date(date)
      date.strftime("%m/%d/%Y")
    end

    def invoice_coverage_date(date)
      date.next_month.beginning_of_month.strftime('%b %Y').to_s
    rescue StandardError
      nil
    end

    def coverage_kind(census_employee = nil)
      return "" if census_employee.blank? || census_employee.employee_role.blank?
      enrolled = census_employee.active_benefit_group_assignment.try(:aasm_state)
      if enrolled.present? && enrolled != "initialized"
        begin
          #kind = census_employee.employee_role.person.primary_family.enrolled_including_waived_hbx_enrollments.map(&:plan).map(&:coverage_kind).sort.reverse.uniq.join(", ")
          kind = census_employee.employee_role.person.primary_family.enrolled_including_waived_hbx_enrollments.map(&:plan).map(&:coverage_kind).sort.reverse.join(", ")
        rescue StandardError
          kind = ""
        end
      else
        kind = ""
      end
      kind.titleize
    end

    def render_plan_offerings(benefit_group, coverage_type)
      start_on = benefit_group.plan_year.start_on.year
      reference_plan = benefit_group.reference_plan
      carrier_profile = reference_plan.carrier_profile
      employer_profile = benefit_group.employer_profile
      profile_and_service_area_pairs = CarrierProfile.carrier_profile_service_area_pairs_for(employer_profile, start_on)
      query = profile_and_service_area_pairs.select { |pair| pair.first == carrier_profile.id }

      if coverage_type == "dental" && benefit_group.dental_plan_option_kind == "single_plan"
        plan_count = benefit_group.elected_dental_plan_ids.count
        "#{plan_count} Plans"
      elsif coverage_type == "dental" && benefit_group.dental_plan_option_kind == "single_carrier"
        plan_count = Plan.shop_dental_by_active_year(reference_plan.active_year).by_carrier_profile(reference_plan.carrier_profile).count
        "All #{reference_plan.carrier_profile.legal_name} Plans (#{plan_count})"
      else
        return "1 Plan Only" if benefit_group.single_plan_type?
        return "Sole Source Plan" if benefit_group.plan_option_kind == 'sole_source'

        if benefit_group.plan_option_kind == "single_carrier"
          plan_count = if EnrollRegistry[:service_area].settings(:service_area_model).item == 'single'
                         Plan.shop_health_by_active_year(reference_plan.active_year).by_carrier_profile(reference_plan.carrier_profile).count
                       else
                         Plan.for_service_areas_and_carriers(query, start_on).shop_market.check_plan_offerings_for_single_carrier.health_coverage.and(hios_id: /-01/).count
                       end
          "All #{reference_plan.carrier_profile.legal_name} Plans (#{plan_count})"
        else
          plan_count = if EnrollRegistry[:service_area].settings(:service_area_model).item == 'single'
                         Plan.shop_health_by_active_year(reference_plan.active_year).by_health_metal_levels([reference_plan.metal_level]).count
                       else
                         Plan.for_service_areas_and_carriers(profile_and_service_area_pairs, start_on).shop_market.check_plan_offerings_for_metal_level.health_coverage.by_metal_level(reference_plan.metal_level).and(hios_id: /-01/).count
                       end
          "#{reference_plan.metal_level.titleize} Plans (#{plan_count})"
        end
      end
    end

  # deprecated
    def get_benefit_groups_for_census_employee
      # TODO
      plan_years = @employer_profile.plan_years.select{|py| (PlanYear::PUBLISHED + ['draft']).include?(py.aasm_state) && py.end_on > TimeKeeper.date_of_record}
      benefit_groups = plan_years.flat_map(&:benefit_groups)
      renewing_benefit_groups = @employer_profile.renewing_plan_year.benefit_groups if @employer_profile.renewing_plan_year.present?
      [benefit_groups, (renewing_benefit_groups || [])]
    end

    def get_benefit_packages_for_census_employee
      initial_benefit_packages = @benefit_sponsorship&.current_benefit_application&.benefit_packages unless @benefit_sponsorship.current_benefit_application&.terminated?
      renewing_benefit_packages = @benefit_sponsorship&.renewal_benefit_application&.benefit_packages if @benefit_sponsorship.renewal_benefit_application.present?
      [(initial_benefit_packages || []), (renewing_benefit_packages || [])]
    end

    def off_cycle_benefit_packages_for_census_employee
      @benefit_sponsorship.off_cycle_benefit_application&.benefit_packages || []
    end

    def reinstated_benefit_packages_with_future_date_for_census_employee
      @benefit_sponsorship.future_active_reinstated_benefit_application&.benefit_packages || []
    end

    def current_option_for_initial_benefit_package
      bga = @census_employee.active_benefit_group_assignment
      return bga.benefit_package_id if bga&.benefit_package_id
      application = @employer_profile.current_benefit_application
      return nil if application.blank?
      return nil if application.benefit_packages.empty?
      application.benefit_packages[0].id
    end

    def current_option_for_off_cycle_benefit_package
      bga = @census_employee.off_cycle_benefit_group_assignment
      return bga.benefit_package_id if bga&.benefit_package_id
      application = @employer_profile.off_cycle_benefit_application
      return nil if application.blank?
      return nil if application.benefit_packages.empty?
      application.benefit_packages[0].id
    end

    def current_option_for_renewal_benefit_package
      bga = @census_employee.renewal_benefit_group_assignment
      return bga.benefit_package_id if bga&.benefit_package_id
      application = @employer_profile.renewal_benefit_application
      return nil if application.blank?
      application.default_benefit_group || application.benefit_packages[0].id
    end

    def current_option_for_reinstated_benefit_package
      bga = @census_employee.future_active_reinstated_benefit_group_assignment
      return bga.benefit_package_id if bga&.benefit_package_id
      application = @employer_profile.future_active_reinstated_benefit_application
      return nil if application.blank?
      return nil if application.benefit_packages.empty?
      application.benefit_packages[0].id
    end

    def cobra_effective_date(census_employee)
      disabled = current_user.has_hbx_staff_role? ? false : true
      content_tag(:div) do
        content_tag(:span,"COBRA/Continuation Effective Date:  ") +
          content_tag(:span, :class => "confirm-cobra",:style => "display:inline;") do
            content_tag(:input, nil, :type => "text",:class => "text-center date-picker", :value => census_employee.suggested_cobra_effective_date, :disabled => disabled)
          end
      end.html_safe
    end

    def cobra_button(census_employee)
      disabled = true
      disabled = false if census_employee.is_cobra_coverage_eligible? && (current_user.has_hbx_staff_role? || !census_employee.cobra_eligibility_expired?)

      button_text = 'COBRA'
      toggle_class = ".cobra_confirm_"
      if census_employee.cobra_terminated?
        button_text = 'COBRA REINSTATE'
        toggle_class = ".cobra_reinstate_"
        disabled = !current_user.has_hbx_staff_role?
      end
      content_tag(:a, :class => "show_confirm show_cobra_confirm btn btn-primary", :id => "show_cobra_confirm_#{census_employee.id}",:disabled => disabled) do
        content_tag(:span, button_text, :class => "hidden-xs hidden-sm visible-md visible-lg",
                                        :onclick => "$(this).closest('tr').nextAll('#{toggle_class}#{census_employee.id}').toggle()")
      end
    end

    def show_cobra_fields?(employer_profile, user)
      return true if user&.has_hbx_staff_role?
      return false if employer_profile.blank?

      # TODO
      plan_year = employer_profile.renewing_plan_year || employer_profile.active_plan_year || employer_profile.published_plan_year

      return false if plan_year.blank?
      return false if plan_year.is_renewing? && !employer_profile.is_converting?

      plan_year.open_enrollment_contains?(TimeKeeper.date_of_record)
    end

    def rehire_date_min(census_employee)
      return 0 if census_employee.blank?

      if census_employee.employment_terminated?
        (census_employee.employment_terminated_on - TimeKeeper.date_of_record).to_i + 1
      elsif census_employee.cobra_eligible? || census_employee.cobra_linked? || census_employee.cobra_terminated?
        (census_employee.cobra_begin_date - TimeKeeper.date_of_record).to_i + 1
      else
        0
      end
    end

    def display_families_tab(user)
      user.has_broker_agency_staff_role? || user.has_general_agency_staff_role? || user.is_active_broker?(@employer_profile) if user.present?
    end

    def show_or_hide_claim_quote_button(employer_profile)
      return true if employer_profile.show_plan_year.blank?
      return true if employer_profile.plan_years_with_drafts_statuses
      return true if employer_profile.has_active_state? && employer_profile.show_plan_year.try(:terminated_on).present? && employer_profile.show_plan_year.terminated_on > TimeKeeper.date_of_record
      return false if !employer_profile.plan_years_with_drafts_statuses && employer_profile.published_plan_year.present?
      false
    end

    def claim_quote_warnings(employer_profile)
      plan_year = employer_profile.plan_years.draft[0]
      return [], "#claimQuoteModal" unless plan_year

      if plan_year.is_renewing?
        [
["<p>Claiming this quote will replace your existing renewal draft plan year. This action cannot be undone. Are you sure you wish to claim this quote?</p><p>If you wish to review the quote details prior to claiming, please contact your Broker to provide you with a pdf copy of this quote.</p>"], "#claimQuoteWarning"
]
      else
        [
["<p>Claiming this quote will replace your existing draft plan year. This action cannot be undone. Are you sure you wish to claim this quote?</p><p>If you wish to review the quote details prior to claiming, please contact your Broker to provide you with a pdf copy of this quote.</p>"], "#claimQuoteWarning"
]
      end
    end

    def display_employee_status_transitions(census_employee)
      content = "<input type='text' class='form-control date-picker date-field'/>" || nil if CensusEmployee::EMPLOYMENT_ACTIVE_STATES.include? census_employee.aasm_state
      content = "<input type='text' class='form-control date-picker date-field'/>" || nil if CensusEmployee::EMPLOYMENT_TERMINATED_STATES.include? census_employee.aasm_state
      links = link_to "Terminate", "javascript:;", data: { "content": content.to_s }, onclick: "EmployerProfile.changeCensusEmployeeStatus($(this))", class: "manual" if CensusEmployee::EMPLOYMENT_ACTIVE_STATES.include? census_employee.aasm_state
      if CensusEmployee::EMPLOYMENT_TERMINATED_STATES.include? census_employee.aasm_state
        links = "#{link_to('Rehire', 'javascript:;', data: { "content": content.to_s }, onclick: 'EmployerProfile.changeCensusEmployeeStatus($(this))',
                                                     class: 'manual')} #{link_to('COBRA', 'javascript:;',
                                                                                 onclick: 'EmployerProfile.changeCensusEmployeeStatus($(this))')}"
      end
      [links, content]
    end

    def is_rehired(census_employee)
      (census_employee.coverage_terminated_on.present? && (census_employee.is_eligible? || census_employee.employee_role_linked?))
    end

    def is_terminated(census_employee)
      (census_employee.coverage_terminated_on.present? && !(census_employee.is_eligible? || census_employee.employee_role_linked?))
    end

    def selected_benefit_plan(plan)
      case plan
      when :single_issuer then 'One Carrier'
      when :metal_level then 'One Level'
      when :single_product then 'A Single Plan'
      end
    end

    def display_sic_field_for_employer?
      Settings.aca.employer_has_sic_field
    end

    def display_referred_by_field_for_employer?
      Settings.aca.employer_registration_has_referred_by_field
    end

    def check_for_canceled_wst?(application)
      application.workflow_state_transitions.any?{|wst| wst.from_state.to_s == "active" && wst.to_state.to_s == "canceled"}
    end

    def is_ben_app_within_reinstate_period?(application)
      offset_months = EnrollRegistry[:benefit_application_reinstate].setting(:offset_months).item
      start_on = application.benefit_sponsor_catalog.effective_period.min
      end_on = application.benefit_sponsor_catalog.effective_period.max + offset_months.months
      (start_on..end_on).cover?(TimeKeeper.date_of_record)
    end

    def display_reinstate_benefit_application?(application)
      return false if term_eligible_for_reinstate(application)
      return false unless [:terminated, :termination_pending, :retroactive_canceled].include?(application.aasm_state) || (application.canceled? && application.reinstated_id.blank? && check_for_canceled_wst?(application))
      is_ben_app_within_reinstate_period?(application)
    end

  #TODO: Temp condition until we have some resolution
    def term_eligible_for_reinstate(application)
      [:terminated, :termination_pending].include?(application.aasm_state) && application.end_on.next_day > application.benefit_sponsor_catalog.effective_period.max
    end
  end
end
