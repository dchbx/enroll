class Insured::GroupSelectionController < ApplicationController
  include Insured::GroupSelectionHelper

  before_action :initialize_common_vars, only: [:new, :create, :terminate_selection]
  before_action :set_vars_for_market, only: [:new]
  # before_action :is_under_open_enrollment, only: [:new]

  def new
    set_bookmark_url
    hbx_enrollment = build_hbx_enrollment
    @effective_on_date = hbx_enrollment.effective_on if hbx_enrollment.present? #building hbx enrollment before hand to display correct effective date on CCH page
    @employee_role = @person.active_employee_roles.first if @employee_role.blank? && @person.has_active_employee_role?
    @market_kind = select_market(@person, params)
    @resident = Person.find(params[:person_id]) if Person.find(params[:person_id]).resident_role?
    if @market_kind == 'individual' || (@person.try(:has_active_employee_role?) && @person.try(:has_active_consumer_role?)) || @resident
      if params[:hbx_enrollment_id].present?
        session[:pre_hbx_enrollment_id] = params[:hbx_enrollment_id]
        pre_hbx = HbxEnrollment.find(params[:hbx_enrollment_id])
        pre_hbx.update_current(changing: true) if pre_hbx.present?
      end

      correct_effective_on = calculate_effective_on(market_kind: 'individual', employee_role: nil, benefit_group: nil)
      @benefit = HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.select{|bcp| bcp.contains?(correct_effective_on)}.first.benefit_packages.select{|bp|  bp[:title] == "individual_health_benefits_#{correct_effective_on.year}"}.first
    end

    insure_hbx_enrollment_for_shop_qle_flow
    @waivable = @hbx_enrollment.can_complete_shopping? if @hbx_enrollment.present?

    @qle = (@change_plan == 'change_by_qle' or @enrollment_kind == 'sep')
    @benefit_group = select_benefit_group(@qle, @employee_role)
    @new_effective_on = calculate_effective_on(market_kind: @market_kind, employee_role: @employee_role, benefit_group: @benefit_group)

    generate_coverage_family_members_for_cobra
    # Set @new_effective_on to the date choice selected by user if this is a QLE with date options available.
    @new_effective_on = Date.strptime(params[:effective_on_option_selected], '%m/%d/%Y') if params[:effective_on_option_selected].present?
  end

  def create
    keep_existing_plan = params[:commit] == "Keep existing plan"
    @market_kind = params[:market_kind].present? ? params[:market_kind] : 'shop'
    return redirect_to purchase_insured_families_path(change_plan: @change_plan, terminate: 'terminate') if params[:commit] == "Terminate Plan"

    raise "You must select at least one Eligible applicant to enroll in the healthcare plan" if params[:family_member_ids].blank?
    family_member_ids = params.require(:family_member_ids).collect() do |index, family_member_id|
      BSON::ObjectId.from_string(family_member_id)
    end
    hbx_enrollment = build_hbx_enrollment
    if (keep_existing_plan && @hbx_enrollment.present?)
      sep = @hbx_enrollment.is_shop? ? @hbx_enrollment.family.earliest_effective_shop_sep : @hbx_enrollment.family.earliest_effective_ivl_sep

      if sep.present?
        hbx_enrollment.special_enrollment_period_id = sep.id
      end

      hbx_enrollment.plan = @hbx_enrollment.plan
    end

    hbx_enrollment.hbx_enrollment_members = hbx_enrollment.hbx_enrollment_members.select do |member|
      family_member_ids.include? member.applicant_id
    end
    hbx_enrollment.generate_hbx_signature

    @family.hire_broker_agency(current_user.person.broker_role.try(:id))
    hbx_enrollment.writing_agent_id = current_user.person.try(:broker_role).try(:id)
    hbx_enrollment.original_application_type = session[:original_application_type]
    broker_role = current_user.person.broker_role
    hbx_enrollment.broker_agency_profile_id = broker_role.broker_agency_profile_id if broker_role

    hbx_enrollment.coverage_kind = @coverage_kind
    hbx_enrollment.validate_for_cobra_eligiblity(@employee_role)

    if hbx_enrollment.save
      hbx_enrollment.inactive_related_hbxs # FIXME: bad name, but might go away
      if keep_existing_plan
        hbx_enrollment.update_coverage_kind_by_plan
        redirect_to purchase_insured_families_path(change_plan: @change_plan, market_kind: @market_kind, coverage_kind: @coverage_kind, hbx_enrollment_id: hbx_enrollment.id)
      elsif @change_plan.present?
        redirect_to insured_plan_shopping_path(:id => hbx_enrollment.id, change_plan: @change_plan, market_kind: @market_kind, coverage_kind: @coverage_kind, enrollment_kind: @enrollment_kind)
      else
        # FIXME: models should update relationships, not the controller
        hbx_enrollment.benefit_group_assignment.update(hbx_enrollment_id: hbx_enrollment.id) if hbx_enrollment.benefit_group_assignment.present?
        redirect_to insured_plan_shopping_path(:id => hbx_enrollment.id, market_kind: @market_kind, coverage_kind: @coverage_kind, enrollment_kind: @enrollment_kind)
      end
    else
      raise "You must select the primary applicant to enroll in the healthcare plan"
    end
  rescue Exception => error
    flash[:error] = error.message
    logger.error "#{error.message}\n#{error.backtrace.join("\n")}"
    employee_role_id = @employee_role.id if @employee_role
    consumer_role_id = @consumer_role.id if @consumer_role
    return redirect_to new_insured_group_selection_path(person_id: @person.id, employee_role_id: employee_role_id, change_plan: @change_plan, market_kind: @market_kind, consumer_role_id: consumer_role_id, enrollment_kind: @enrollment_kind)
  end

  def terminate_selection
    @hbx_enrollments = @family.enrolled_hbx_enrollments.select{|pol| pol.may_terminate_coverage? } || []
  end

  def terminate_confirm
    @hbx_enrollment = HbxEnrollment.find(params.require(:hbx_enrollment_id))
  end

  def terminate
    term_date = Date.strptime(params.require(:term_date),"%m/%d/%Y")
    hbx_enrollment = HbxEnrollment.find(params.require(:hbx_enrollment_id))
    if hbx_enrollment.may_terminate_coverage? && term_date >= TimeKeeper.date_of_record
      hbx_enrollment.termination_submitted_on = TimeKeeper.datetime_of_record
      hbx_enrollment.terminate_benefit(term_date)
      redirect_to family_account_path
    else
      redirect_to :back
    end
  end

  private

  def build_hbx_enrollment
    case @market_kind
    when 'shop'
      @employee_role = @person.active_employee_roles.first if @employee_role.blank? and @person.has_active_employee_role?

      if @hbx_enrollment.present?
        @change_plan = 'change_by_qle' if @hbx_enrollment.is_special_enrollment?
        if @employee_role == @hbx_enrollment.employee_role
          benefit_group = @hbx_enrollment.benefit_group
          benefit_group_assignment = @hbx_enrollment.benefit_group_assignment
        else
          benefit_group = @employee_role.benefit_group(qle: (@change_plan == 'change_by_qle' or @enrollment_kind == 'sep'))
          benefit_group_assignment = benefit_group_assignment_by_plan_year(@employee_role, benefit_group, @change_plan, @enrollment_kind)
        end
      end
      @coverage_household.household.new_hbx_enrollment_from(
        employee_role: @employee_role,
        resident_role: @person.resident_role,
        coverage_household: @coverage_household,
        benefit_group: benefit_group,
        benefit_group_assignment: benefit_group_assignment,
        qle: (@change_plan == 'change_by_qle' or @enrollment_kind == 'sep'),
        opt_effective_on: @optional_effective_on)
    when 'individual'
      @coverage_household.household.new_hbx_enrollment_from(
        consumer_role: @person.consumer_role,
        resident_role: @person.resident_role,
        coverage_household: @coverage_household,
        qle: (@change_plan == 'change_by_qle' or @enrollment_kind == 'sep'),
        opt_effective_on: @optional_effective_on)
    when 'coverall'
      @coverage_household.household.new_hbx_enrollment_from(
        consumer_role: @person.consumer_role,
        resident_role: @person.resident_role,
        coverage_household: @coverage_household,
        qle: (@change_plan == 'change_by_qle' or @enrollment_kind == 'sep'),
        opt_effective_on: @optional_effective_on)
    end
  end


  def initialize_common_vars
    person_id = params.require(:person_id)
    @person = Person.find(person_id)
    @family = @person.primary_family
    @coverage_household = @family.active_household.immediate_family_coverage_household
    @hbx_enrollment = HbxEnrollment.find(params[:hbx_enrollment_id]) if params[:hbx_enrollment_id].present?

    if params[:employee_role_id].present?
      emp_role_id = params.require(:employee_role_id)
      @employee_role = @person.employee_roles.detect { |emp_role| emp_role.id.to_s == emp_role_id.to_s }
      @role = @employee_role
    elsif params[:resident_role_id].present?
      @resident_role = @person.resident_role
      @role = @resident_role
    else
      @consumer_role = @person.consumer_role
      @role = @consumer_role
    end

    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
    @coverage_kind = params[:coverage_kind].present? ? params[:coverage_kind] : 'health'
    @enrollment_kind = params[:enrollment_kind].present? ? params[:enrollment_kind] : ''
    @shop_for_plans = params[:shop_for_plans].present? ? params{:shop_for_plans} : ''
    @optional_effective_on = params[:effective_on_option_selected].present? ? Date.strptime(params[:effective_on_option_selected], '%m/%d/%Y') : nil
  end

  def set_vars_for_market
    if (@change_plan == 'change_by_qle' || @enrollment_kind == 'sep')
      @disable_market_kind = "shop"
      @disable_market_kind = "individual" if select_market(@person, params) == "shop"
    end

    if @hbx_enrollment.present? && @change_plan == "change_plan"
      @mc_market_kind = @hbx_enrollment.kind == "employer_sponsored" ? "shop" : "individual"
      @mc_coverage_kind = @hbx_enrollment.coverage_kind
    end
  end

  def generate_coverage_family_members_for_cobra
    if @market_kind == 'shop' && !(@change_plan == 'change_by_qle' || @enrollment_kind == 'sep') && @employee_role.present? && @employee_role.is_cobra_status?
      hbx_enrollment = @family.active_household.hbx_enrollments.shop_market.enrolled_and_renewing.effective_desc.detect { |hbx| hbx.may_terminate_coverage? }
      if hbx_enrollment.present?
        @coverage_family_members_for_cobra = hbx_enrollment.hbx_enrollment_members.map(&:family_member)
      end
    end
  end
end
