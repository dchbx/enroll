require_relative 'employer'

module Api::V1::MobileApiHelper

  def render_employee_contacts_json(staff, offices)
    #TODO null handling
    staff.map do |s|
      {
          first: s.first_name, last: s.last_name, phone: s.work_phone.to_s,
          mobile: s.mobile_phone.to_s, emails: [s.work_email_or_best]
      }
    end + offices.map do |loc|
      {
          first: loc.address.kind.capitalize, last: "Office", phone: loc.phone.to_s,
          address_1: loc.address.address_1, address_2: loc.address.address_2,
          city: loc.address.city, state: loc.address.state, zip: loc.address.zip
      }
    end
  end

  def employer_summary(employer_profile: nil, year: nil, num_enrolled: nil,
                       num_waived: nil, num_terminated: nil, staff: nil,
                       offices: nil, include_details_url: false)
    renewals_offset_in_months = Settings.aca.shop_market.renewal_application.earliest_start_prior_to_effective_on.months

    summary = {
        employer_name: employer_profile.legal_name,
        employees_total: employer_profile.roster_size,
        employees_enrolled: num_enrolled,
        employees_waived: num_waived,
        employees_terminated: num_terminated,
        open_enrollment_begins: year ? year.open_enrollment_start_on : nil,
        open_enrollment_ends: year ? year.open_enrollment_end_on : nil,
        plan_year_begins: year ? year.start_on : nil,
        renewal_in_progress: year ? year.is_renewing? : nil,
        renewal_application_available: year ? (year.start_on >> renewals_offset_in_months) : nil,
        renewal_application_due: year ? year.due_date_for_publish : nil,
        binder_payment_due: "",
        minimum_participation_required: year ? year.minimum_enrolled_count : nil,
    }
    if staff or offices then
      summary[:contact_info] = render_employee_contacts_json(staff || [], offices || [])
    end
    if include_details_url then
      summary[:employer_details_url] = Rails.application.routes.url_helpers.api_v1_mobile_api_employer_details_path(employer_profile.id)
      summary[:employee_roster_url] = Rails.application.routes.url_helpers.api_v1_mobile_api_employee_roster_path(employer_profile.id)
    end
    summary
  end

  def eligibility_rule_for(benefit_group)
    case benefit_group.effective_on_offset
      when 0 then
        "First of the month following or coinciding with date of hire"
      when 1 then
        "First of the month following date of hire"
      else
        "#{benefit_group.effective_on_kind.humanize} following #{benefit_group.effective_on_offset} days"
    end
  end

  MAX_DENTAL_PLANS = 13

  def render_plans_by!(rendered)
    count_dental_plans = rendered[:elected_dental_plans].try(:count)
    plans_by, plans_by_summary_text = case rendered[:plan_option_kind]
                                        when "single_carrier"
                                        then
                                          ["All Plans From A Single Carrier",
                                           "All #{rendered[:carrier_name]} Plans"]
                                        when "metal_level"
                                        then
                                          ["All Plans From A Given Metal Level",
                                           "All #{rendered[:metal_level]} Level Plans"]
                                        when "single_plan"
                                        then
                                          if count_dental_plans.nil? then
                                            ["A Single Plan", "Reference Plan Only"]
                                          else
                                            [count_dental_plans < MAX_DENTAL_PLANS ?
                                                 "Custom (#{ count_dental_plans } Plans)" :
                                                 "All Plans"] * 2
                                          end
                                        else
                                          nil
                                      end

    rendered[:plans_by] = plans_by
    rendered[:plans_by_summary_text] = plans_by_summary_text
    rendered
  end

  def display_metal_level(plan)
    (plan.active_year == 2015 || plan.coverage_kind == "health" ? plan.metal_level : plan.dental_level).try(:titleize)
  end

  def render_plan_offering(plan: nil, plan_option_kind: nil, relationship_benefits: [], employer_estimated_max: 0, employee_estimated_min: 0, employee_estimated_max: 0, elected_dental_plans: nil)
    render_plans_by!(
        reference_plan_name: plan.name.try(:upcase),
        reference_plan_HIOS_id: plan.hios_id,
        carrier_name: plan.carrier_profile.try(:legal_name),
        plan_type: plan.try(:plan_type).try(:upcase),
        metal_level: display_metal_level(plan),
        plan_option_kind: plan_option_kind,
        employer_contribution_by_relationship:
            Hash[relationship_benefits.map do |rb|
              [rb.relationship, rb.offered ? rb.premium_pct : nil]
            end],
        elected_dental_plans: elected_dental_plans,
        estimated_employer_max_monthly_cost: employer_estimated_max,
        estimated_plan_participant_min_monthly_cost: employee_estimated_min,
        estimated_plan_participant_max_monthly_cost: employee_estimated_max
    )
  end

  def render_plan_offerings_by_year(plan_year)
    plan_year.benefit_groups.compact.map do |benefit_group|

      health_offering = render_plan_offering(
          plan: benefit_group.reference_plan,
          plan_option_kind: benefit_group.plan_option_kind,
          relationship_benefits: benefit_group.relationship_benefits,
          employer_estimated_max: benefit_group.monthly_employer_contribution_amount,
          employee_estimated_min: benefit_group.monthly_min_employee_cost,
          employee_estimated_max: benefit_group.monthly_max_employee_cost)

      elected_dental_plans = benefit_group.elected_dental_plans.map do |p|
        {
            carrier_name: p.carrier_profile.legal_name,
            plan_name: p.name
        }
      end if benefit_group.elected_dental_plan_ids.count < MAX_DENTAL_PLANS

      dental_offering = render_plan_offering(
          plan: benefit_group.dental_reference_plan,
          plan_option_kind: benefit_group.plan_option_kind,
          relationship_benefits: benefit_group.dental_relationship_benefits,
          employer_estimated_max: benefit_group.monthly_employer_contribution_amount(benefit_group.dental_reference_plan),
          employee_estimated_min: benefit_group.monthly_min_employee_cost('dental'),
          employee_estimated_max: benefit_group.monthly_max_employee_cost('dental'),
          elected_dental_plans: elected_dental_plans) if benefit_group.is_offering_dental? && benefit_group.dental_reference_plan

      {
          benefit_group_name: benefit_group.title,
          eligibility_rule: eligibility_rule_for(benefit_group),
          health: health_offering,
          dental: dental_offering
      }
    end
  end

  def render_employer_details_json(employer_profile: nil, year: nil, num_enrolled: nil,
                                   num_waived: nil, num_terminated: nil, total_premium: nil,
                                   employer_contribution: nil, employee_contribution: nil)
    details = employer_summary(employer_profile: employer_profile, year: year,
                               num_enrolled: num_enrolled, num_waived: num_waived,
                               num_terminated: num_terminated)
    details[:total_premium] = total_premium
    details[:employer_contribution] = employer_contribution
    details[:employee_contribution] = employee_contribution
    details[:active_general_agency] = employer_profile.active_general_agency_legal_name # Note: queries DB
    details[:plan_offerings] = Hash[active_and_renewal_plan_years(employer_profile).map do |period, py|
      [period, py ? render_plan_offerings_by_year(py) : nil]
    end]
    details
  end

  def marshall_employer_details_json employer_profile, report_date
    plan_year = employer_profile.show_plan_year
    if plan_year
      enrollments = employer_profile.enrollments_for_billing(report_date) || []
      premium_amt_total = enrollments.map(&:total_premium).sum
      employee_cost_total = enrollments.map(&:total_employee_cost).sum
      employer_contribution_total = enrollments.map(&:total_employer_contribution).sum
      enrolled, waived, terminated = count_enrolled_waived_and_terminated_employees plan_year

      render_employer_details_json(employer_profile: employer_profile,
                                   year: plan_year,
                                   num_enrolled: enrolled,
                                   num_waived: waived,
                                   num_terminated: terminated,
                                   total_premium: premium_amt_total,
                                   employer_contribution: employer_contribution_total,
                                   employee_contribution: employee_cost_total
      )
    else
      render_employer_details_json(employer_profile: employer_profile)
    end
  end

  def benefit_group_ids_of_enrollments_in_status(enrollments, status_list)
    enrollments.select do |enrollment|
      status_list.include? (enrollment.aasm_state)
    end.map(&:benefit_group_assignment_id)
  end

  #
  # A faster way of counting employees who are enrolled vs waived vs terminated
  # where enrolled + waived = counting towards SHOP minimum healthcare participation
  # We first do the query to find families with appropriate enrollments,
  # then check again inside the map/reduce to get only those enrollments.
  # This avoids undercounting, e.g. two family members working for the same employer.
  #
  def count_employees_by_enrollment_status benefit_group_assignments = []
    enrolled_or_renewal = HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES
    waived = HbxEnrollment::WAIVED_STATUSES
    terminated = HbxEnrollment::TERMINATED_STATUSES

    return [] if benefit_group_assignments.blank?
    id_list = benefit_group_assignments.map(&:id) #.uniq
    families = Family.where(:"households.hbx_enrollments".elem_match => {
        :"benefit_group_assignment_id".in => id_list,
        :aasm_state.in => enrolled_or_renewal + waived + terminated,
        :kind => "employer_sponsored",
        :coverage_kind => "health",
        :is_active => true #???
    })

    all_enrollments = families.map { |f| f.households.map { |h| h.hbx_enrollments } }.flatten.compact
    relevant_enrollments = all_enrollments.select do |enrollment|
      enrollment.kind == "employer_sponsored" &&
          enrollment.coverage_kind == "health" &&
          enrollment.is_active
    end

    enrolled_ids = benefit_group_ids_of_enrollments_in_status(relevant_enrollments, enrolled_or_renewal)
    waived_ids = benefit_group_ids_of_enrollments_in_status(relevant_enrollments, waived)
    terminated_ids = benefit_group_ids_of_enrollments_in_status(relevant_enrollments, terminated)

    # return count of enrolled, count of waived, count of terminated
    # -- only including those originally asked for
    [enrolled_ids, waived_ids, terminated_ids].map { |found_ids| (found_ids & id_list).count }
  end

  def detect_plan_in_states(employer_profile, states)
    employer_profile.plan_years.detect { |py| states.include? py.aasm_state }
  end

  def active_and_renewal_plan_years(employer_profile)
    {
        active: detect_plan_in_states(employer_profile, PlanYear::PUBLISHED),
        renewal: detect_plan_in_states(employer_profile, PlanYear::RENEWING_PUBLISHED_STATE + PlanYear::RENEWING)
    }
    #TODO: renewal when appropriate, see employer_profiles_controller.sort_plan_years
  end

  def employers_and_broker_agency user, broker_agency_id
    employer = Api::V1::Employer.new broker_agency_id: broker_agency_id, user: user
    employer.organization do |broker_agency_profile, organization, broker_role|
      break unless organization
      employer_profiles = organization.map { |o| o.employer_profile }
      broker_name = user.person.first_name if broker_role

      {broker_name: broker_name,
       broker_agency: broker_agency_profile.legal_name,
       broker_agency_id: broker_agency_profile.id,
       broker_clients: marshall_employer_summaries(employer_profiles)} if broker_agency_profile
    end
  end

  def marshall_employer_summaries employer_profiles
    return [] if employer_profiles.blank?
    employer = Api::V1::Employer.new employer_profiles: employer_profiles
    employer.summaries
  end

end


