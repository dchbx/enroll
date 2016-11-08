module Insured::FamiliesHelper

  def plan_shopping_dependent_text(hbx_enrollment)
    subscriber, dependents = hbx_enrollment.hbx_enrollment_members.partition {|h| h.is_subscriber == true }
    if subscriber.present? && dependents.count == 0
      ("<span class='dependent-text'>#{subscriber.first.person.full_name}</span>").html_safe
    elsif subscriber.blank? && dependents.count == 1
      ("<span class='dependent-text'>#{dependents.first.person.full_name}</span>").html_safe
    elsif subscriber.blank? && dependents.count > 1
      (link_to(pluralize(dependents.count, "dependent"), "", data: {toggle: "modal", target: "#dependentsList"}, class: "dependent-text")).html_safe + render(partial: "shared/dependents_list_modal", locals: {subscriber: subscriber, dependents: dependents})
    else
      ("<span class='dependent-text'>#{subscriber.first.person.full_name}</span>" + " + " + link_to(pluralize(dependents.count, "dependent"), "", data: {toggle: "modal", target: "#dependentsList"}, class: "dependent-text")).html_safe + render(partial: "shared/dependents_list_modal", locals: {subscriber: subscriber, dependents: dependents})
    end
  end

  def current_premium hbx_enrollment
    if hbx_enrollment.kind == 'employer_sponsored'
      hbx_enrollment.total_employee_cost
    else
      hbx_enrollment.total_premium > hbx_enrollment.applied_aptc_amount.to_f ? hbx_enrollment.total_premium - hbx_enrollment.applied_aptc_amount.to_f : 0
    end
  end

  def hide_policy_selected_date?(hbx_enrollment)
    return true if hbx_enrollment.created_at.blank?
    return true if hbx_enrollment.benefit_group.present? && hbx_enrollment.benefit_group.is_congress && hbx_enrollment.created_at <= Time.zone.parse("2015-11-09 14:00:00").utc
    return true if !hbx_enrollment.consumer_role_id.blank? && hbx_enrollment.created_at <= Time.zone.parse("2015-10-13 14:00:00").utc
    false
  end

  def shift_purchase_time(policy)
    policy.created_at.in_time_zone('Eastern Time (US & Canada)')
  end

  def shift_waived_time(policy)
    (policy.submitted_at || policy.created_at).in_time_zone('Eastern Time (US & Canada)')
  end

  def format_policy_purchase_date(policy)
    format_date(shift_purchase_time(policy))
  end

  def format_policy_purchase_time(policy)
    shift_purchase_time(policy).strftime("%-I:%M%p")
  end

  def format_policy_waived_date(policy)
    format_date(shift_waived_time(policy))
  end

  def format_policy_waived_time(policy)
    shift_waived_time(policy).strftime("%-I:%M%p")
  end

  def render_plan_type_details(plan)
    plan_details = [ plan.try(:plan_type).try(:upcase) ].compact

    metal_level = display_dental_metal_level(plan)

    if plan_level = plan.try(:metal_level).try(:humanize)
      plan_details << "<span class=\"#{plan_level.try(:downcase)}-icon\">#{metal_level}</span>"
    end

    if plan.try(:nationwide)
      plan_details << "NATIONWIDE NETWORK"
    end

    plan_details.inject([]) do |data, element|
      data << "#{element}"
    end.join("&nbsp<label class='separator'></label>").html_safe
  end

  def qle_link_generater(qle, index)
    options = {class: 'qle-menu-item'}
    data = {
      title: qle.title, id: qle.id.to_s, label: qle.event_kind_label,
      is_self_attested: qle.is_self_attested,
      current_date: TimeKeeper.date_of_record.strftime("%m/%d/%Y")
    }

    if qle.tool_tip.present?
      data.merge!(toggle: 'tooltip', placement: index > 1 ? 'top' : 'bottom')
      options.merge!(data: data, title: qle.tool_tip)
    else
      options.merge!(data: data)
    end
    link_to qle.title, "javascript:void(0)", options
  end

  def generate_options_for_effective_on_kinds(effective_on_kinds, qle_date)
    return [] if effective_on_kinds.blank?

    options = []
    effective_on_kinds.each do |kind|
      case kind
      when 'date_of_event'
        options << [qle_date.to_s, kind]
      when 'fixed_first_of_next_month'
        options << [(qle_date.end_of_month + 1.day).to_s, kind]
      end
    end

    options
  end

  def newhire_enrollment_eligible?(employee_role)
    return false if employee_role.blank? || employee_role.census_employee.blank?

    employee_role.census_employee.newhire_enrollment_eligible? && employee_role.can_select_coverage?
  end

  def disable_make_changes_button?(hbx_enrollment)
    # return false if IVL
    return false if hbx_enrollment.census_employee.blank?

    # Enable the button under these conditions
      # 1) plan year under open enrollment period
      # 2) new hire covered under enrolment period
      # 3) qle enrolmlent period check

    return false if hbx_enrollment.benefit_group.plan_year.open_enrollment_contains?(TimeKeeper.date_of_record)
    return false if hbx_enrollment.census_employee.new_hire_enrollment_period.cover?(TimeKeeper.date_of_record)
    return false if hbx_enrollment.is_special_enrollment? && hbx_enrollment.special_enrollment_period.present? && hbx_enrollment.special_enrollment_period.contains?(TimeKeeper.date_of_record)

    # Disable only  if non of the above conditions match
    return true
  end

  def has_writing_agent?(employee_role_or_person)
    if employee_role_or_person.is_a?(EmployeeRole)
      employee_role_or_person.employer_profile.active_broker_agency_account.writing_agent rescue false
    elsif employee_role_or_person.is_a?(Person)
       employee_role_or_person.primary_family.current_broker_agency.writing_agent.present? rescue false
    end
  end


  def display_aasm_state?(enrollment)
    if enrollment.is_shop?
      true
    else
      ['coverage_selected', 'coverage_canceled', 'coverage_terminated', 'auto_renewing'].include?(enrollment.aasm_state.to_s)
    end
  end

end
